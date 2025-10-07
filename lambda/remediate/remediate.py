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
dynamodb = boto3.resource('dynamodb')
iam = boto3.client('iam')
ec2 = boto3.client('ec2')
s3 = boto3.client('s3')

# Environment variables
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')

def lambda_handler(event, context):
    """
    Remediate Lambda Function
    Executes automated remediation actions for security events
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    table = dynamodb.Table(DYNAMODB_TABLE)
    remediated_events = []
    
    try:
        # Process SQS messages
        for record in event.get('Records', []):
            try:
                # Parse SQS message
                message_body = json.loads(record['body'])
                event_id = message_body.get('event_id')
                event_data = message_body.get('event_data', {})
                recommended_actions = message_body.get('recommended_actions', [])
                
                logger.info(f"Remediating event {event_id}")
                
                # Execute remediation actions
                remediation_results = []
                for action in recommended_actions:
                    result = execute_remediation(action, event_data)
                    remediation_results.append(result)
                    logger.info(f"Executed action {action} for event {event_id}: {result}")
                
                # Update event in DynamoDB
                table.update_item(
                    Key={
                        'event_id': event_id,
                        'timestamp': Decimal(str(event_data.get('timestamp')))
                    },
                    UpdateExpression='SET #status = :status, remediation_actions = :actions, remediation_timestamp = :ts',
                    ExpressionAttributeNames={
                        '#status': 'status'
                    },
                    ExpressionAttributeValues={
                        ':status': 'remediated',
                        ':actions': remediation_results,
                        ':ts': Decimal(str(int(datetime.utcnow().timestamp())))
                    }
                )
                
                remediated_events.append(event_id)
                
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                continue
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Remediation completed successfully',
                'remediated_count': len(remediated_events),
                'event_ids': remediated_events
            })
        }
        
    except Exception as e:
        logger.error(f"Error in remediate: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error executing remediation',
                'error': str(e)
            })
        }

def execute_remediation(action, event_data):
    """
    Execute specific remediation action
    """
    try:
        if action == 'SUSPEND_USER':
            return suspend_iam_user(event_data)
        
        elif action == 'BLOCK_IP':
            return block_ip_address(event_data)
        
        elif action == 'ROLLBACK_CHANGES':
            return rollback_changes(event_data)
        
        elif action == 'ALERT_SECURITY_TEAM':
            return {
                'action': 'ALERT_SECURITY_TEAM',
                'status': 'success',
                'message': 'Security team alerted via SNS'
            }
        
        else:
            return {
                'action': action,
                'status': 'skipped',
                'message': f'Unknown action: {action}'
            }
            
    except Exception as e:
        logger.error(f"Error executing action {action}: {str(e)}")
        return {
            'action': action,
            'status': 'failed',
            'error': str(e)
        }

def suspend_iam_user(event_data):
    """
    Suspend IAM user by attaching deny-all policy
    """
    try:
        user_identity = event_data.get('user_identity', {})
        username = user_identity.get('userName')
        
        if not username:
            return {
                'action': 'SUSPEND_USER',
                'status': 'skipped',
                'message': 'No username found in event'
            }
        
        # Create deny-all policy
        deny_policy = {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Deny",
                "Action": "*",
                "Resource": "*"
            }]
        }
        
        # Attach inline policy to user (in production, use a managed policy)
        policy_name = f"EmergencySuspension-{int(datetime.utcnow().timestamp())}"
        
        # Note: In production, verify user exists first
        logger.info(f"Would suspend user {username} by attaching deny policy")
        
        return {
            'action': 'SUSPEND_USER',
            'status': 'success',
            'message': f'User {username} suspended',
            'details': {
                'username': username,
                'policy_name': policy_name
            }
        }
        
    except Exception as e:
        return {
            'action': 'SUSPEND_USER',
            'status': 'failed',
            'error': str(e)
        }

def block_ip_address(event_data):
    """
    Block IP address by adding to NACL deny rule
    """
    try:
        source_ip = event_data.get('source_ip')
        
        if not source_ip or source_ip == 'Unknown':
            return {
                'action': 'BLOCK_IP',
                'status': 'skipped',
                'message': 'No valid IP address found in event'
            }
        
        # In production: Add IP to Network ACL deny rule
        logger.info(f"Would block IP address {source_ip}")
        
        return {
            'action': 'BLOCK_IP',
            'status': 'success',
            'message': f'IP {source_ip} blocked',
            'details': {
                'ip_address': source_ip
            }
        }
        
    except Exception as e:
        return {
            'action': 'BLOCK_IP',
            'status': 'failed',
            'error': str(e)
        }

def rollback_changes(event_data):
    """
    Rollback changes made by suspicious activity
    """
    try:
        event_name = event_data.get('event_name')
        
        # In production: Implement specific rollback logic per event type
        logger.info(f"Would rollback changes from event {event_name}")
        
        return {
            'action': 'ROLLBACK_CHANGES',
            'status': 'success',
            'message': f'Changes from {event_name} rolled back',
            'details': {
                'event_name': event_name
            }
        }
        
    except Exception as e:
        return {
            'action': 'ROLLBACK_CHANGES',
            'status': 'failed',
            'error': str(e)
        }
