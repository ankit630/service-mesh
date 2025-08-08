from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import time
import random
import socket
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configuration
VERSION = "1.0.0"
SERVICE_NAME = "backend-service"
INSTANCE_ID = os.environ.get('HOSTNAME', socket.gethostname())

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': SERVICE_NAME,
        'version': VERSION,
        'instance': INSTANCE_ID,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/message', methods=['GET'])
def get_message():
    """Main API endpoint that returns a message with metadata"""
    
    # Simulate some processing time
    processing_time = random.uniform(0.1, 0.5)
    time.sleep(processing_time)
    
    # Get request headers for tracing
    request_id = request.headers.get('X-Request-ID', f'req-{int(time.time())}')
    source = request.headers.get('X-Source', 'unknown')
    
    # Simulate occasional failures for demo purposes
    failure_rate = 0.1  # 10% failure rate
    if random.random() < failure_rate:
        return jsonify({
            'error': 'Random service failure for demo purposes',
            'service': SERVICE_NAME,
            'instance': INSTANCE_ID,
            'request_id': request_id
        }), 500
    
    response_data = {
        'message': f'Hello from {SERVICE_NAME}!',
        'version': VERSION,
        'instance': INSTANCE_ID,
        'processing_time_ms': round(processing_time * 1000, 2),
        'request_id': request_id,
        'source': source,
        'timestamp': datetime.utcnow().isoformat(),
        'metadata': {
            'hostname': INSTANCE_ID,
            'python_version': '3.11',
            'framework': 'Flask'
        }
    }
    
    print(f"📨 Request processed: ID={request_id}, Source={source}, Time={processing_time:.3f}s")
    
    return jsonify(response_data)

@app.route('/api/load', methods=['GET'])
def simulate_load():
    """Endpoint to simulate high load for testing"""
    iterations = int(request.args.get('iterations', 1000))
    
    start_time = time.time()
    
    # Simulate CPU intensive work
    result = 0
    for i in range(iterations):
        result += i * i
    
    end_time = time.time()
    processing_time = end_time - start_time
    
    return jsonify({
        'service': SERVICE_NAME,
        'instance': INSTANCE_ID,
        'iterations': iterations,
        'result': result,
        'processing_time_ms': round(processing_time * 1000, 2),
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/chain', methods=['GET'])
def service_chain():
    """Endpoint that calls another service (for multi-service demos)"""
    next_service = request.args.get('next', None)
    
    if not next_service:
        return jsonify({
            'message': 'This is the end of the chain',
            'service': SERVICE_NAME,
            'instance': INSTANCE_ID,
            'chain_position': 'terminal'
        })
    
    # This would call another service in a real scenario
    return jsonify({
        'message': f'Chain call from {SERVICE_NAME}',
        'service': SERVICE_NAME,
        'instance': INSTANCE_ID,
        'next_service': next_service,
        'chain_position': 'intermediate'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 4000))
    print(f"🚀 {SERVICE_NAME} v{VERSION} starting on port {port}")
    print(f"🏷️  Instance ID: {INSTANCE_ID}")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    )