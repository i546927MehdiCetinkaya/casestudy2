import json
import os
import boto3
from datetime import datetime
from decimal import Decimal

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

REMEDIATION_QUEUE_URL = os.environ['REMEDIATION_QUEUE_URL']
NOTIFY_QUEUE_URL = os.environ['NOTIFY_QUEUE_URL']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']

def count_recent_attempts(source_ip, event_type):
    try:
        table = dynamodb.Table(DYNAMODB_TABLE)
        current_time = int(datetime.utcnow().timestamp())
        two_minutes_ago = current_time - 120
        
        response = table.scan(
            FilterExpression='source_ip = :ip AND event_name = :event_type AND #ts >= :time',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':ip': source_ip,
                ':event_type': event_type,
                ':time': Decimal(str(two_minutes_ago))
            }
        )
        return response.get('Count', 0)
    except:
        return 0

def lambda_handler(event, context):
    table = dynamodb.Table(DYNAMODB_TABLE)
    
    for record in event.get('Records', []):
        try:
            message = json.loads(record['body'])
            event_id = message['event_id']
            event_name = message['event_name']
            source_ip = message['source_ip']
            severity = message['severity']
            
            # Count attempts for brute force detection
            attempts = count_recent_attempts(source_ip, event_name) if event_name in ['failed_login', 'web_login_failed'] else 0
            
            # Escalate severity based on attempts
            risk_score = 10
            if attempts >= 10:
                severity = 'HIGH'
                risk_score = 90
            elif attempts >= 5:
                severity = 'HIGH'
                risk_score = 70
            elif attempts >= 3:
                severity = 'HIGH'
                risk_score = 50
            
            table.update_item(
                Key={'event_id': event_id, 'timestamp': Decimal(str(message['timestamp']))},
                UpdateExpression='SET #status = :status, risk_score = :risk_score, severity = :severity',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'analyzed',
                    ':risk_score': Decimal(str(risk_score)),
                    ':severity': severity
                }
            )
            
            # Notify only at thresholds: 3, 5, 10, 15, 20
            if severity == 'HIGH' and attempts in [3, 5, 10, 15, 20]:
                sqs.send_message(
                    QueueUrl=NOTIFY_QUEUE_URL,
                    MessageBody=json.dumps({
                        'event_id': event_id,
                        'severity': severity,
                        'event_name': event_name,
                        'source_ip': source_ip,
                        'risk_score': risk_score,
                        'failed_attempts': attempts
                    })
                )
        except Exception as e:
            print(f"Error: {e}")
            continue
    
    return {'statusCode': 200}
