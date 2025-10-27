import json
import os
import boto3
from datetime import datetime

sns = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    for record in event.get('Records', []):
        try:
            message = json.loads(record['body'])
            event_id = message['event_id']
            severity = message.get('severity', 'UNKNOWN')
            event_name = message.get('event_name', 'Unknown')
            source_ip = message.get('source_ip', 'Unknown')
            risk_score = message.get('risk_score', 0)
            attempts = message.get('failed_attempts', 0)
            
            notification = f"""
╔══════════════════════════════════════════════════════════╗
║              SECURITY EVENT NOTIFICATION                  ║
╚══════════════════════════════════════════════════════════╝

Event ID:       {event_id}
Severity:       {severity}
Event:          {event_name}
Source IP:      {source_ip}
Attempts:       {attempts}
Risk Score:     {risk_score}/100
Time:           {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

⚠️  RECOMMENDED ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Investigate this activity immediately
2. Review access logs
3. Consider blocking IP if unauthorized

This is an automated message from the SOAR Security Platform.
"""
            
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"Security Alert - {severity} - {event_name}",
                Message=notification,
                MessageAttributes={
                    'severity': {'StringValue': severity, 'DataType': 'String'},
                    'event_id': {'StringValue': event_id, 'DataType': 'String'}
                }
            )
        except Exception as e:
            print(f"Error: {e}")
            continue
    
    return {'statusCode': 200}
