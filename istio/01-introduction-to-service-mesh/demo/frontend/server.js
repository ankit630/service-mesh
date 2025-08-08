const express = require('express');
const axios = require('axios');

const app = express();
const PORT = 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://backend:4000';

app.use(express.static('public'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'frontend', timestamp: new Date() });
});

// Main route that calls backend
app.get('/api/data', async (req, res) => {
  try {
    console.log(`Calling backend at: ${BACKEND_URL}/api/message`);
    
    const response = await axios.get(`${BACKEND_URL}/api/message`, {
      timeout: 5000,
      headers: {
        'X-Request-ID': req.headers['x-request-id'] || `req-${Date.now()}`,
        'X-Source': 'frontend-service'
      }
    });
    
    res.json({
      success: true,
      frontend_message: 'Hello from Frontend!',
      backend_data: response.data,
      timestamp: new Date(),
      request_id: req.headers['x-request-id']
    });
    
  } catch (error) {
    console.error('Backend call failed:', error.message);
    
    res.status(500).json({
      success: false,
      error: 'Backend service unavailable',
      details: error.message,
      timestamp: new Date()
    });
  }
});

// Simple HTML page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Istio Demo - Frontend</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            button { padding: 10px 20px; font-size: 16px; margin: 10px; }
            .response { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .error { background: #ffe6e6; border-left: 4px solid #ff0000; }
            .success { background: #e6ffe6; border-left: 4px solid #00aa00; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Istio Service Mesh Demo</h1>
            <p>This frontend service communicates with a backend service.</p>
            
            <button onclick="testConnection()">Test Backend Connection</button>
            <button onclick="checkHealth()">Check Health</button>
            
            <div id="result"></div>
        </div>

        <script>
            async function testConnection() {
                const result = document.getElementById('result');
                result.innerHTML = '<p>🔄 Calling backend...</p>';
                
                try {
                    const response = await fetch('/api/data');
                    const data = await response.json();
                    
                    if (data.success) {
                        result.innerHTML = \`
                            <div class="response success">
                                <h3>✅ Success!</h3>
                                <p><strong>Frontend:</strong> \${data.frontend_message}</p>
                                <p><strong>Backend:</strong> \${data.backend_data.message}</p>
                                <p><strong>Backend Version:</strong> \${data.backend_data.version}</p>
                                <p><strong>Timestamp:</strong> \${data.timestamp}</p>
                            </div>
                        \`;
                    } else {
                        throw new Error(data.error);
                    }
                } catch (error) {
                    result.innerHTML = \`
                        <div class="response error">
                            <h3>❌ Error</h3>
                            <p>\${error.message}</p>
                        </div>
                    \`;
                }
            }

            async function checkHealth() {
                const result = document.getElementById('result');
                try {
                    const response = await fetch('/health');
                    const data = await response.json();
                    
                    result.innerHTML = \`
                        <div class="response success">
                            <h3>💚 Health Check</h3>
                            <p><strong>Status:</strong> \${data.status}</p>
                            <p><strong>Service:</strong> \${data.service}</p>
                            <p><strong>Timestamp:</strong> \${data.timestamp}</p>
                        </div>
                    \`;
                } catch (error) {
                    result.innerHTML = \`
                        <div class="response error">
                            <h3>💔 Health Check Failed</h3>
                            <p>\${error.message}</p>
                        </div>
                    \`;
                }
            }
        </script>
    </body>
    </html>
  `);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Frontend service running on port ${PORT}`);
  console.log(`📡 Backend URL: ${BACKEND_URL}`);
});