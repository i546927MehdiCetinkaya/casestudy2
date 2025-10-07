from flask import Flask, jsonify, request
import boto3
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# AWS clients
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'eu-central-1'))
table_name = os.environ.get('DYNAMODB_TABLE', 'casestudy2-dev-events')

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'soar-api'
    }), 200

@app.route('/ready', methods=['GET'])
def ready():
    """Readiness check endpoint"""
    try:
        # Check DynamoDB connection
        table = dynamodb.Table(table_name)
        table.table_status
        return jsonify({
            'status': 'ready',
            'timestamp': datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return jsonify({
            'status': 'not ready',
            'error': str(e)
        }), 503

@app.route('/api/events', methods=['GET'])
def get_events():
    """Get security events"""
    try:
        table = dynamodb.Table(table_name)
        
        # Query parameters
        limit = int(request.args.get('limit', 100))
        severity = request.args.get('severity')
        
        if severity:
            response = table.query(
                IndexName='severity-index',
                KeyConditionExpression='severity = :sev',
                ExpressionAttributeValues={':sev': severity},
                Limit=limit,
                ScanIndexForward=False
            )
        else:
            response = table.scan(Limit=limit)
        
        return jsonify({
            'events': response.get('Items', []),
            'count': len(response.get('Items', []))
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching events: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/<event_id>', methods=['GET'])
def get_event(event_id):
    """Get specific event by ID"""
    try:
        table = dynamodb.Table(table_name)
        
        response = table.query(
            KeyConditionExpression='event_id = :eid',
            ExpressionAttributeValues={':eid': event_id}
        )
        
        items = response.get('Items', [])
        if items:
            return jsonify(items[0]), 200
        else:
            return jsonify({'error': 'Event not found'}), 404
            
    except Exception as e:
        logger.error(f"Error fetching event: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get event statistics"""
    try:
        table = dynamodb.Table(table_name)
        
        # Get counts by severity
        stats = {
            'total': 0,
            'by_severity': {
                'HIGH': 0,
                'MEDIUM': 0,
                'LOW': 0
            }
        }
        
        for severity in ['HIGH', 'MEDIUM', 'LOW']:
            response = table.query(
                IndexName='severity-index',
                KeyConditionExpression='severity = :sev',
                ExpressionAttributeValues={':sev': severity},
                Select='COUNT'
            )
            count = response.get('Count', 0)
            stats['by_severity'][severity] = count
            stats['total'] += count
        
        return jsonify(stats), 200
        
    except Exception as e:
        logger.error(f"Error fetching stats: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
