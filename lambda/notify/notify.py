import json
import os
import boto3
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# AWS clients
sns = boto3.client('sns')

# Environment variables
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    """
    Notify Lambda Function
    Sends notifications for security events via SNS
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    notified_events = []
    
    try:
        # Process SQS messages
        for record in event.get('Records', []):
            try:
                # Parse SQS message
                message_body = json.loads(record['body'])
                event_id = message_body.get('event_id')
                
                logger.info(f"Sending notification for event {event_id}")
                
                # Format notification message
                notification = format_notification(message_body)
                
                # Send SNS notification
                response = sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=f"Security Alert - {message_body.get('severity')} - {message_body.get('event_name')}",
                    Message=notification,
                    MessageAttributes={
                        'severity': {
                            'StringValue': message_body.get('severity', 'UNKNOWN'),
                            'DataType': 'String'
                        },
                        'event_id': {
                            'StringValue': event_id,
                            'DataType': 'String'
                        }
                    }
                )
                
                logger.info(f"Notification sent for event {event_id}: {response['MessageId']}")
                notified_events.append(event_id)
                
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                continue
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notifications sent successfully',
                'notified_count': len(notified_events),
                'event_ids': notified_events
            })
        }
        
    except Exception as e:
        logger.error(f"Error in notify: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error sending notifications',
                'error': str(e)
            })
        }

def format_notification(event_data):
    """
    Format a human-readable notification message
    """
    severity = event_data.get('severity', 'UNKNOWN')
    event_name = event_data.get('event_name', 'Unknown Event')
    source_ip = event_data.get('source_ip', 'Unknown')
    event_id = event_data.get('event_id', 'Unknown')
    risk_score = event_data.get('risk_score', 0)
    analysis = event_data.get('analysis', 'No analysis available')
    
    message = f"""
╔══════════════════════════════════════════════════════════╗
║              SECURITY EVENT NOTIFICATION                  ║
╚══════════════════════════════════════════════════════════╝

📊 EVENT DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Event ID:       {event_id}
Severity:       {severity}
Event Name:     {event_name}
Source IP:      {source_ip}
Risk Score:     {risk_score}/100
Timestamp:      {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

🔍 ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{analysis}

⚡ RECOMMENDED ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
    
    if severity == 'HIGH':
        message += """
1. ⚠️  Immediate investigation required
2. 🔒 Review access controls
3. 📋 Check audit logs for related activities
4. 👥 Contact security team if unauthorized
"""
    elif severity == 'MEDIUM':
        message += """
1. ⚡ Review within 24 hours
2. 📊 Monitor for additional suspicious activity
3. 📝 Document findings
"""
    else:
        message += """
1. 📊 Standard monitoring
2. 📝 Log for future reference
"""
    
    message += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is an automated message from the SOAR Security Platform.
For more details, check the CloudWatch logs or DynamoDB table.
"""
    
    return message
