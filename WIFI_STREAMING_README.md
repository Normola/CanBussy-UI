# WiFi Connection and Data Streaming

This example demonstrates how to connect to a WiFi network and stream data in your Flutter app.

## Features

- **WiFi Network Scanning**: Discover and list available WiFi networks
- **WiFi Connection**: Connect to selected WiFi networks with password support
- **Connection Monitoring**: Real-time connectivity status monitoring
- **Data Streaming**: Stream data from network endpoints over WiFi
- **Data Display**: View streaming data in real-time

## Usage

1. **Scan for Networks**: Tap the "Scan" button to discover available WiFi networks
2. **Connect to WiFi**: Select a network from the list and enter the password if required
3. **Start Streaming**: Once connected, enter a streaming endpoint URL and start streaming
4. **View Data**: See streaming data appear in real-time in the data display area

## Streaming Endpoint Examples

For testing purposes, you can use these example endpoints:

### Local Test Server
```
http://192.168.1.100:8080/stream
```

### Simple HTTP Server (Python)
Create a simple test server using Python:

```python
# test_server.py
import time
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

class StreamHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/stream':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            
            # Stream data every second
            for i in range(100):
                data = json.dumps({
                    'timestamp': time.time(),
                    'counter': i,
                    'temperature': 20 + (i % 10),
                    'humidity': 50 + (i % 20)
                })
                self.wfile.write(f"{data}\n".encode())
                self.wfile.flush()
                time.sleep(1)
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), StreamHandler)
    print("Server running on http://0.0.0.0:8080")
    server.serve_forever()
```

Run with: `python test_server.py`

### JSON Data Stream
```
http://192.168.1.100:8080/data
```

## Permissions

The app requires the following permissions on Android:

- `ACCESS_WIFI_STATE` - To check WiFi state
- `CHANGE_WIFI_STATE` - To connect to WiFi networks
- `ACCESS_NETWORK_STATE` - To monitor network connectivity
- `CHANGE_NETWORK_STATE` - To change network settings
- `ACCESS_FINE_LOCATION` - Required for WiFi scanning on Android 6+
- `INTERNET` - For data streaming

## Dependencies

- `wifi_scan` - For scanning WiFi networks
- `plugin_wifi_connect` - For connecting to WiFi networks
- `connectivity_plus` - For monitoring connectivity status
- `permission_handler` - For requesting Android permissions
- `http` - For HTTP data streaming

## Notes

- WiFi connection functionality is primarily designed for Android
- Location permission is required for WiFi scanning on Android 6.0+
- The app will automatically request necessary permissions
- Data streaming requires an active WiFi connection
- Streaming data is displayed in real-time with timestamps
