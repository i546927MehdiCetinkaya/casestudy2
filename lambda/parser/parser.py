import json
import os
import boto3
import logging
from datetime import datetime
from uuid import uuid4

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# AWS clients
sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

# Environment variables
ENGINE_QUEUE_URL = os.environ.get('ENGINE_QUEUE_URL')
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')

def lambda_handler(event, context):
    """
    Parser Lambda Function
    Parses incoming security events from CloudTrail and forwards to Engine
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    table = dynamodb.Table(DYNAMODB_TABLE)
    processed_events = []
    
    try:
        # Process SQS messages
        for record in event.get('Records', []):
            try:
                # Parse SQS message
                message_body = json.loads(record['body'])
                
                # Extract CloudTrail event details
                event_detail = message_body.get('detail', {})
                event_name = event_detail.get('eventName', 'Unknown')
                event_source = event_detail.get('eventSource', 'Unknown')
                user_identity = event_detail.get('userIdentity', {})
                source_ip = event_detail.get('sourceIPAddress', 'Unknown')
                
                # Create normalized event
                event_id = str(uuid4())
                timestamp = int(datetime.utcnow().timestamp())
                
                normalized_event = {
                    'event_id': event_id,
                    'timestamp': timestamp,
                    'event_name': event_name,
                    'event_source': event_source,
                    'source_ip': source_ip,
                    'user_identity': user_identity,
                    'raw_event': json.dumps(event_detail),
                    'status': 'parsed',
                    'severity': classify_severity(event_name, event_source)
                }
                
                # Store in DynamoDB
                table.put_item(Item=normalized_event)
                logger.info(f"Stored event {event_id} in DynamoDB")
                
                # Send to Engine Queue
                sqs.send_message(
                    QueueUrl=ENGINE_QUEUE_URL,
                    MessageBody=json.dumps(normalized_event),
                    MessageAttributes={
                        'event_type': {
                            'StringValue': event_name,
                            'DataType': 'String'
                        },
                        'severity': {
                            'StringValue': normalized_event['severity'],
                            'DataType': 'String'
                        }
                    }
                )
                logger.info(f"Sent event {event_id} to Engine Queue")
                
                processed_events.append(event_id)
                
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                continue
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Events processed successfully',
                'processed_count': len(processed_events),
                'event_ids': processed_events
            })
        }
        
    except Exception as e:
        logger.error(f"Error in parser: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing events',
                'error': str(e)
            })
        }

def classify_severity(event_name, event_source):
    """
    Classify event severity based on event name and source
    """
    high_risk_events = [
        'DeleteBucket', 'DeleteTrail', 'StopLogging',
        'PutBucketPolicy', 'CreateAccessKey', 'DeleteUser',
        'AttachUserPolicy', 'PutUserPolicy'
    ]
    
    medium_risk_events = [
        'CreateBucket', 'CreateUser', 'CreateRole',
        'PutBucketAcl', 'AuthorizeSecurityGroupIngress'
    ]
    
    if event_name in high_risk_events:
        return 'HIGH'
    elif event_name in medium_risk_events:
        return 'MEDIUM'
    else:
        return 'LOW'
