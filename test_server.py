#!/usr/bin/env python3
"""
Simple test server for WiFi data streaming demo.
This server provides a streaming endpoint that sends JSON data every second.
"""

import time
import json
import random
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
from datetime import datetime

class StreamHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/stream':
            self.send_streaming_response()
        elif self.path == '/data':
            self.send_json_data()
        elif self.path == '/':
            self.send_status_page()
        else:
            self.send_response(404)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Not Found')

    def do_POST(self):
        if self.path == '/data':
            self.receive_data()
        else:
            self.send_response(404)
            self.end_headers()

    def send_streaming_response(self):
        """Send continuous streaming data"""
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        print(f"Starting stream for {self.client_address}")
        
        try:
            # Stream data every second for 2 minutes
            for i in range(120):
                timestamp = datetime.now().isoformat()
                data = {
                    'timestamp': timestamp,
                    'counter': i,
                    'temperature': round(20 + random.uniform(-5, 15), 2),
                    'humidity': round(50 + random.uniform(-10, 30), 2),
                    'pressure': round(1013.25 + random.uniform(-50, 50), 2),
                    'battery': round(100 - (i * 0.5), 1),
                    'signal_strength': random.randint(-80, -30)
                }
                
                message = json.dumps(data)
                self.wfile.write(f"{message}\n".encode())
                self.wfile.flush()
                time.sleep(1)
                
        except Exception as e:
            print(f"Stream ended for {self.client_address}: {e}")

    def send_json_data(self):
        """Send single JSON response"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        data = {
            'timestamp': datetime.now().isoformat(),
            'device_id': 'test-device-001',
            'location': {'lat': 40.7128, 'lng': -74.0060},
            'sensors': {
                'temperature': round(random.uniform(15, 35), 2),
                'humidity': round(random.uniform(30, 80), 2),
                'pressure': round(random.uniform(980, 1040), 2)
            },
            'status': 'active'
        }
        
        response = json.dumps(data, indent=2)
        self.wfile.write(response.encode())

    def send_status_page(self):
        """Send HTML status page"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>CanBussy Test Server</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 4px; }
                code { background: #e0e0e0; padding: 2px 4px; border-radius: 2px; }
            </style>
        </head>
        <body>
            <h1>CanBussy WiFi Streaming Test Server</h1>
            <p>Server is running and ready to serve data streams.</p>
            
            <h2>Available Endpoints:</h2>
            
            <div class="endpoint">
                <h3>GET /stream</h3>
                <p>Continuous data streaming endpoint</p>
                <p><strong>Usage:</strong> <code>http://YOUR_IP:8080/stream</code></p>
                <p>Returns: Continuous JSON data stream (one object per line)</p>
            </div>
            
            <div class="endpoint">
                <h3>GET /data</h3>
                <p>Single JSON response endpoint</p>
                <p><strong>Usage:</strong> <code>http://YOUR_IP:8080/data</code></p>
                <p>Returns: Single JSON object with sensor data</p>
            </div>
            
            <div class="endpoint">
                <h3>POST /data</h3>
                <p>Receive data from client</p>
                <p><strong>Usage:</strong> Send JSON data to <code>http://YOUR_IP:8080/data</code></p>
                <p>Accepts: JSON data via POST request</p>
            </div>
            
            <h2>Testing with CanBussy App:</h2>
            <ol>
                <li>Connect your Android device to the same WiFi network as this server</li>
                <li>Find your computer's IP address (e.g., 192.168.1.100)</li>
                <li>In the app, use: <code>http://YOUR_IP:8080/stream</code></li>
                <li>Start streaming to see live data</li>
            </ol>
        </body>
        </html>
        """
        
        self.wfile.write(html.encode())

    def receive_data(self):
        """Receive and log data from client"""
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode())
            timestamp = datetime.now().isoformat()
            print(f"[{timestamp}] Received data from {self.client_address}: {data}")
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                'status': 'success',
                'timestamp': timestamp,
                'received': data
            }
            self.wfile.write(json.dumps(response).encode())
            
        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Invalid JSON data')

    def log_message(self, format, *args):
        """Override to customize logging"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {format % args}")

def get_local_ip():
    """Get the local IP address"""
    import socket
    try:
        # Connect to a remote address to determine local IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
        return local_ip
    except Exception:
        return "localhost"

if __name__ == '__main__':
    HOST = '0.0.0.0'  # Listen on all interfaces
    PORT = 8080
    
    local_ip = get_local_ip()
    
    server = HTTPServer((HOST, PORT), StreamHandler)
    
    print("=" * 60)
    print("CanBussy WiFi Streaming Test Server")
    print("=" * 60)
    print(f"Server running on:")
    print(f"  Local: http://localhost:{PORT}")
    print(f"  Network: http://{local_ip}:{PORT}")
    print()
    print("Available endpoints:")
    print(f"  Stream: http://{local_ip}:{PORT}/stream")
    print(f"  Data: http://{local_ip}:{PORT}/data")
    print()
    print("Use Ctrl+C to stop the server")
    print("=" * 60)
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.shutdown()
        print("Server stopped.")
