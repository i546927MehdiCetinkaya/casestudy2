import json
import os
import boto3
import logging
from datetime import datetime
from decimal import Decimal

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# AWS clients
sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

# Environment variables
REMEDIATION_QUEUE_URL = os.environ.get('REMEDIATION_QUEUE_URL')
NOTIFY_QUEUE_URL = os.environ.get('NOTIFY_QUEUE_URL')
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')

def count_recent_failed_logins(source_ip, event_type):
    """
    Count failed login attempts from an IP in the last 2 minutes FOR SPECIFIC EVENT TYPE
    SSH and web logins are tracked separately
    """
    try:
        table = dynamodb.Table(DYNAMODB_TABLE)
        current_time = int(datetime.utcnow().timestamp())
        two_minutes_ago = current_time - 120  # 2 minutes (120 seconds)
        
        # Query DynamoDB for recent failed logins from this IP for THIS SPECIFIC EVENT TYPE
        response = table.scan(
            FilterExpression='source_ip = :ip AND event_name = :event_type AND #ts >= :time',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':ip': source_ip,
                ':event_type': event_type,
                ':time': Decimal(str(two_minutes_ago))
            }
        )
        
        count = response.get('Count', 0)
        logger.info(f"Found {count} recent {event_type} attempts from {source_ip}")
        return count
        
    except Exception as e:
        logger.error(f"Error counting failed logins: {str(e)}")
        return 0

def lambda_handler(event, context):
    """
    Engine Lambda Function
    Analyzes parsed events and determines remediation actions
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    table = dynamodb.Table(DYNAMODB_TABLE)
    analyzed_events = []
    
    try:
        # Process SQS messages
        for record in event.get('Records', []):
            try:
                # Parse SQS message
                message_body = json.loads(record['body'])
                event_id = message_body.get('event_id')
                
                logger.info(f"Analyzing event {event_id}")
                
                # Analyze event
                analysis_result = analyze_event(message_body)
                
                # Update event in DynamoDB with new severity
                table.update_item(
                    Key={
                        'event_id': event_id,
                        'timestamp': Decimal(str(message_body.get('timestamp')))
                    },
                    UpdateExpression='SET #status = :status, analysis = :analysis, risk_score = :risk_score, severity = :severity',
                    ExpressionAttributeNames={
                        '#status': 'status'
                    },
                    ExpressionAttributeValues={
                        ':status': 'analyzed',
                        ':analysis': analysis_result['analysis'],
                        ':risk_score': Decimal(str(analysis_result['risk_score'])),
                        ':severity': analysis_result['final_severity']
                    }
                )
                
                # If high risk, send to remediation and notification
                if analysis_result['requires_remediation']:
                    # Send to remediation queue
                    remediation_payload = {
                        'event_id': event_id,
                        'event_data': message_body,
                        'recommended_actions': analysis_result['recommended_actions']
                    }
                    
                    sqs.send_message(
                        QueueUrl=REMEDIATION_QUEUE_URL,
                        MessageBody=json.dumps(remediation_payload)
                    )
                    logger.info(f"Sent event {event_id} to Remediation Queue")
                
                # Send notification ONLY at specific thresholds (3rd, 5th, 10th attempt)
                final_severity = analysis_result['final_severity']
                failed_attempts = analysis_result.get('failed_attempts', 0)
                
                # Notify only at key milestones to avoid spam
                should_notify = (
                    final_severity == 'HIGH' and 
                    failed_attempts in [3, 5, 10, 15, 20]  # Only these specific counts
                )
                
                if should_notify:
                    notification_payload = {
                        'event_id': event_id,
                        'severity': final_severity,
                        'event_name': message_body.get('event_name'),
                        'source_ip': message_body.get('source_ip'),
                        'analysis': analysis_result['analysis'],
                        'risk_score': analysis_result['risk_score'],
                        'failed_attempts': failed_attempts
                    }
                    
                    sqs.send_message(
                        QueueUrl=NOTIFY_QUEUE_URL,
                        MessageBody=json.dumps(notification_payload)
                    )
                    logger.info(f"Sent event {event_id} to Notify Queue (HIGH severity, {failed_attempts} attempts)")
                else:
                    logger.info(f"Event {event_id} has {final_severity} severity ({failed_attempts} attempts) - no notification (not at threshold)")
                
                analyzed_events.append(event_id)
                
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                continue
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Events analyzed successfully',
                'analyzed_count': len(analyzed_events),
                'event_ids': analyzed_events
            })
        }
        
    except Exception as e:
        logger.error(f"Error in engine: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error analyzing events',
                'error': str(e)
            })
        }

def analyze_event(event_data):
    """
    Analyze event and determine risk score and remediation needs
    """
    event_name = event_data.get('event_name')
    severity = event_data.get('severity')
    source_ip = event_data.get('source_ip')
    
    # Calculate risk score (0-100)
    risk_score = 0
    
    # Base score on severity
    severity_scores = {
        'HIGH': 70,
        'MEDIUM': 40,
        'LOW': 10
    }
    risk_score += severity_scores.get(severity, 0)
    
    # Brute force detection - check for repeated failed logins
    if event_name in ['failed_login', 'web_login_failed'] and source_ip != 'Unknown':
        failed_attempts = count_recent_failed_logins(source_ip, event_name)
        logger.info(f"IP {source_ip} has {failed_attempts} recent failed login attempts")
        
        # Escalate risk and severity based on EXACT number of attempts
        # Only notify on 3rd, 5th, 10th attempt (not every attempt after threshold)
        if failed_attempts >= 10:
            risk_score += 70  # Critical brute force (10+)
            severity = 'HIGH'
        elif failed_attempts >= 5:
            risk_score += 50  # Critical brute force (5-9)
            severity = 'HIGH'
        elif failed_attempts >= 3:
            risk_score += 30  # Likely brute force (3-4 attempts)
            severity = 'HIGH'
        elif failed_attempts == 2:
            risk_score += 10  # Suspicious activity (2 attempts)
            severity = 'LOW'  # Only log, no notification yet
        elif failed_attempts == 1:
            risk_score = 5  # First attempt
            severity = 'LOW'  # Only log, no notification
    
    # Check for suspicious patterns
    suspicious_ips = ['0.0.0.0', '127.0.0.1']  # Add known malicious IPs
    if source_ip in suspicious_ips:
        risk_score += 20
    
    # High-risk events
    critical_events = [
        'DeleteBucket', 'DeleteTrail', 'StopLogging',
        'DeleteUser', 'DeleteRole'
    ]
    if event_name in critical_events:
        risk_score += 15
    
    # Cap at 100
    risk_score = min(risk_score, 100)
    
    # Determine if remediation is required
    requires_remediation = risk_score >= 60
    
    # Recommended actions
    recommended_actions = []
    if requires_remediation:
        if event_name in critical_events:
            recommended_actions.append('ROLLBACK_CHANGES')
            recommended_actions.append('SUSPEND_USER')
        recommended_actions.append('ALERT_SECURITY_TEAM')
    
    return {
        'risk_score': risk_score,
        'final_severity': severity,  # Return updated severity
        'failed_attempts': failed_attempts if event_name in ['failed_login', 'web_login_failed'] else 0,
        'requires_remediation': requires_remediation,
        'recommended_actions': recommended_actions,
        'analysis': f"Event analyzed with risk score {risk_score} (severity: {severity}). "
                   f"Remediation {'required' if requires_remediation else 'not required'}."
    }
