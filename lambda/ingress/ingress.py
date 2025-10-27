import json
import os
import boto3

sqs = boto3.client('sqs')
PARSER_QUEUE_URL = os.environ['PARSER_QUEUE_URL']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body']) if 'body' in event else event
        
        required = ['eventType', 'sourceIP', 'username', 'timestamp']
        for field in required:
            if field not in body:
                return {'statusCode': 400, 'body': json.dumps({'error': f'Missing: {field}'})}
        
        message = {
            'Source': 'custom.security',
            'DetailType': 'Failed Login Attempt',
            'detail': {
                'eventType': body['eventType'],
                'sourceIP': body['sourceIP'],
                'username': body['username'],
                'timestamp': body['timestamp'],
                'hostname': body.get('hostname', 'unknown'),
                'description': body.get('description', f"Failed login from {body['sourceIP']}"),
                'severity': 'HIGH'
            }
        }
        
        response = sqs.send_message(QueueUrl=PARSER_QUEUE_URL, MessageBody=json.dumps(message))
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Event received',
                'messageId': response['MessageId']
            })
        }
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
