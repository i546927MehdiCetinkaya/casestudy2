import boto3
import json
import os
import time
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# AWS clients
sqs = boto3.client('sqs', region_name=os.environ.get('AWS_REGION', 'eu-central-1'))

# Environment variables
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')

def remediation_worker():
    """
    SOAR Remediation Worker
    Continuously processes remediation actions from SQS queue
    """
    logger.info("SOAR Remediation Worker started")
    
    while True:
        try:
            # Receive messages from SQS
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20,
                MessageAttributeNames=['All']
            )
            
            messages = response.get('Messages', [])
            
            if not messages:
                logger.info("No remediation actions in queue, waiting...")
                continue
            
            for message in messages:
                try:
                    # Parse message
                    body = json.loads(message['Body'])
                    event_id = body.get('event_id')
                    actions = body.get('recommended_actions', [])
                    
                    logger.info(f"Executing remediation for event {event_id}")
                    logger.info(f"Actions: {actions}")
                    
                    # Execute remediation actions
                    execute_remediation(body, actions)
                    
                    # Delete message from queue
                    sqs.delete_message(
                        QueueUrl=QUEUE_URL,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    
                    logger.info(f"Remediation completed for event {event_id}")
                    
                except Exception as e:
                    logger.error(f"Error processing remediation: {str(e)}")
                    continue
            
        except Exception as e:
            logger.error(f"Error in main loop: {str(e)}")
            time.sleep(5)

def execute_remediation(event_data, actions):
    """
    Execute remediation actions
    """
    for action in actions:
        logger.info(f"Executing action: {action}")
        
        if action == 'SUSPEND_USER':
            suspend_user(event_data)
        elif action == 'BLOCK_IP':
            block_ip(event_data)
        elif action == 'ROLLBACK_CHANGES':
            rollback_changes(event_data)
        elif action == 'ALERT_SECURITY_TEAM':
            alert_security_team(event_data)
        else:
            logger.warning(f"Unknown action: {action}")

def suspend_user(event_data):
    """Suspend IAM user"""
    logger.info("Suspending user...")
    # Add IAM suspension logic here
    time.sleep(1)

def block_ip(event_data):
    """Block IP address"""
    logger.info("Blocking IP address...")
    # Add network ACL logic here
    time.sleep(1)

def rollback_changes(event_data):
    """Rollback changes"""
    logger.info("Rolling back changes...")
    # Add rollback logic here
    time.sleep(1)

def alert_security_team(event_data):
    """Alert security team"""
    logger.info("Alerting security team...")
    # SNS notification already handled by notify Lambda
    time.sleep(1)

if __name__ == '__main__':
    remediation_worker()
