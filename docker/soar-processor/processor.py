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
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'eu-central-1'))

# Environment variables
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')

def process_events():
    """
    SOAR Event Processor
    Continuously processes events from SQS queue
    """
    logger.info("SOAR Processor started")
    table = dynamodb.Table(DYNAMODB_TABLE)
    
    while True:
        try:
            # Receive messages from SQS
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20,
                MessageAttributeNames=['All']
            )
            
            messages = response.get('Messages', [])
            
            if not messages:
                logger.info("No messages in queue, waiting...")
                continue
            
            logger.info(f"Processing {len(messages)} messages")
            
            for message in messages:
                try:
                    # Parse message
                    body = json.loads(message['Body'])
                    event_id = body.get('event_id')
                    
                    logger.info(f"Processing event {event_id}")
                    
                    # Process event (add custom logic here)
                    process_event(body, table)
                    
                    # Delete message from queue
                    sqs.delete_message(
                        QueueUrl=QUEUE_URL,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    
                    logger.info(f"Event {event_id} processed successfully")
                    
                except Exception as e:
                    logger.error(f"Error processing message: {str(e)}")
                    continue
            
        except Exception as e:
            logger.error(f"Error in main loop: {str(e)}")
            time.sleep(5)

def process_event(event, table):
    """
    Process individual event
    """
    event_id = event.get('event_id')
    
    # Update processing status
    table.update_item(
        Key={
            'event_id': event_id,
            'timestamp': event.get('timestamp')
        },
        UpdateExpression='SET processing_status = :status, processed_at = :ts',
        ExpressionAttributeValues={
            ':status': 'processed',
            ':ts': int(datetime.utcnow().timestamp())
        }
    )
    
    logger.info(f"Event {event_id} marked as processed")

if __name__ == '__main__':
    process_events()
