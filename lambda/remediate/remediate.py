import json
import os
import boto3
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    """Logs remediation events (no automatic actions)"""
    table = dynamodb.Table(DYNAMODB_TABLE)
    
    for record in event.get('Records', []):
        try:
            message = json.loads(record['body'])
            event_id = message['event_id']
            
            table.update_item(
                Key={'event_id': event_id, 'timestamp': Decimal(str(message['event_data']['timestamp']))},
                UpdateExpression='SET #status = :status, remediation_timestamp = :ts',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'logged',
                    ':ts': Decimal(str(int(datetime.utcnow().timestamp())))
                }
            )
        except Exception as e:
            print(f"Error: {e}")
            continue
    
    return {'statusCode': 200}
