import json
import os
import boto3
from datetime import datetime
from uuid import uuid4
from decimal import Decimal

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

ENGINE_QUEUE_URL = os.environ['ENGINE_QUEUE_URL']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    table = dynamodb.Table(DYNAMODB_TABLE)
    
    for record in event.get('Records', []):
        try:
            message = json.loads(record['body'])
            detail = message.get('detail', message)
            
            event_name = detail.get('eventName', detail.get('eventType', 'Unknown'))
            source_ip = detail.get('sourceIPAddress', detail.get('sourceIP', 'Unknown'))
            
            normalized = {
                'event_id': str(uuid4()),
                'timestamp': int(datetime.utcnow().timestamp()),
                'event_name': event_name,
                'event_source': detail.get('eventSource', detail.get('source', 'Unknown')),
                'source_ip': source_ip,
                'user_identity': detail.get('userIdentity', {}),
                'raw_event': json.dumps(detail),
                'status': 'parsed',
                'severity': detail.get('severity', 'HIGH'),
                'description': detail.get('description', f'{event_name} from {source_ip}')
            }
            
            table.put_item(Item=normalized)
            
            sqs.send_message(
                QueueUrl=ENGINE_QUEUE_URL,
                MessageBody=json.dumps(normalized),
                MessageAttributes={
                    'event_type': {'StringValue': event_name, 'DataType': 'String'},
                    'severity': {'StringValue': normalized['severity'], 'DataType': 'String'}
                }
            )
        except Exception as e:
            print(f"Error: {e}")
            continue
    
    return {'statusCode': 200}
