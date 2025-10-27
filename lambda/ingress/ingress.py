import json
import os
import boto3
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# AWS clients
sqs = boto3.client('sqs')

# Environment variables
PARSER_QUEUE_URL = os.environ.get('PARSER_QUEUE_URL')

def lambda_handler(event, context):
    """
    Ingress Lambda Function
    Receives events from API Gateway and forwards to Parser Queue
    This allows Ubuntu server to send events without AWS credentials (just API key)
    """
    logger.info(f"Received event from API Gateway: {json.dumps(event)}")
    
    try:
        # Parse body from API Gateway
        if 'body' in event:
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        else:
            body = event
        
        logger.info(f"Parsed body: {json.dumps(body)}")
        
        # Validate required fields
        required_fields = ['eventType', 'sourceIP', 'username', 'timestamp']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json'
                    },
                    'body': json.dumps({
                        'error': f'Missing required field: {field}'
                    })
                }
        
        # Create EventBridge-like structure for parser
        event_detail = {
            'eventType': body.get('eventType'),
            'sourceIP': body.get('sourceIP'),
            'username': body.get('username'),
            'timestamp': body.get('timestamp'),
            'hostname': body.get('hostname', 'unknown'),
            'description': body.get('description', f"Failed login from {body.get('sourceIP')}"),
            'severity': body.get('severity', 'HIGH')  # Default to HIGH for failed logins
        }
        
        # Create SQS message in EventBridge format (what parser expects)
        sqs_message = {
            'Source': 'custom.security',
            'DetailType': 'Failed Login Attempt',
            'detail': event_detail
        }
        
        # Send to Parser Queue
        response = sqs.send_message(
            QueueUrl=PARSER_QUEUE_URL,
            MessageBody=json.dumps(sqs_message)
        )
        
        logger.info(f"Sent to Parser Queue. MessageId: {response['MessageId']}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'message': 'Event received and forwarded successfully',
                'messageId': response['MessageId'],
                'eventType': event_detail['eventType'],
                'sourceIP': event_detail['sourceIP']
            })
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    
    except Exception as e:
        logger.error(f"Error in ingress function: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
