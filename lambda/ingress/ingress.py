import json
import os
import boto3

sqs = boto3.client('sqs')
PARSER_QUEUE_URL = os.environ['PARSER_QUEUE_URL']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body']) if 'body' in event else event
        
        # Support both snake_case and camelCase
        event_type = body.get('event_type') or body.get('eventType')
        source_ip = body.get('source_ip') or body.get('sourceIP')
        username = body.get('username')
        timestamp = body.get('timestamp')
        
        if not all([event_type, source_ip, username, timestamp]):
            return {'statusCode': 400, 'body': json.dumps({'error': 'Missing required fields'})}
        
        message = {
            'Source': 'custom.security',
            'DetailType': 'Failed Login Attempt',
            'detail': {
                'eventType': event_type,
                'sourceIP': source_ip,
                'username': username,
                'timestamp': timestamp,
                'hostname': body.get('hostname', 'unknown'),
                'service': body.get('service', 'ssh'),
                'port': body.get('port', 22),
                'description': body.get('description', f"Failed login from {source_ip}"),
                'severity': body.get('severity', 'HIGH')
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
