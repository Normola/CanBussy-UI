import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../core/wifi_service.dart';
import '../core/snackbar.dart';

class WiFiConnectionScreen extends StatefulWidget {
  const WiFiConnectionScreen({super.key});

  @override
  State<WiFiConnectionScreen> createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  final WiFiService _wifiService = WiFiService();
  final DataStreamingService _streamingService = DataStreamingService();
  
  List<WiFiAccessPoint> _availableNetworks = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isStreaming = false;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _streamingEndpointController = TextEditingController();
  
  final List<String> _streamData = [];

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _startConnectivityMonitoring();
    _startDataStreamMonitoring();
  }

  @override
  void dispose() {
    _wifiService.stopConnectivityMonitoring();
    _streamingService.stopDataStreaming();
    _passwordController.dispose();
    _streamingEndpointController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    final connectivity = await _wifiService.getCurrentConnectivity();
    if (mounted) {
      setState(() {
        _connectionStatus = connectivity;
      });
    }
  }

  void _startConnectivityMonitoring() {
    _wifiService.startConnectivityMonitoring();
    _wifiService.connectivityStream.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _connectionStatus = result;
        });
        
        if (result == ConnectivityResult.wifi) {
          showSnackBar(context, 'Connected to WiFi');
        } else if (result == ConnectivityResult.none) {
          showSnackBar(context, 'Disconnected from network');
        }
      }
    });
  }

  void _startDataStreamMonitoring() {
    _streamingService.dataStream.listen(
      (String data) {
        if (mounted) {
          setState(() {
            _streamData.add(data);
            // Keep only the last 100 entries to prevent memory issues
            if (_streamData.length > 100) {
              _streamData.removeAt(0);
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          showSnackBar(context, 'Streaming error: $error');
        }
      },
    );
  }

  Future<void> _scanForNetworks() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final networks = await _wifiService.scanWiFiNetworks();
      if (mounted) {
        setState(() {
          _availableNetworks = networks;
        });
        showSnackBar(context, 'Found ${networks.length} WiFi networks');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to scan networks: $e');
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToWiFi(String ssid, String password) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final success = await _wifiService.connectToWiFi(ssid, password);
      if (mounted) {
        if (success) {
          showSnackBar(context, 'Successfully connected to $ssid');
          _passwordController.clear();
        } else {
          // Manual connection required
          showSnackBar(context, 'WiFi settings opened. Please connect to $ssid manually.');
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Connection error: $e');
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _startStreaming() async {
    final endpoint = _streamingEndpointController.text.trim();
    if (endpoint.isEmpty) {
      showSnackBar(context, 'Please enter a streaming endpoint');
      return;
    }

    setState(() {
      _isStreaming = true;
      _streamData.clear();
    });

    try {
      await _streamingService.startDataStreaming(endpoint);
      if (mounted) {
        showSnackBar(context, 'Started data streaming from $endpoint');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to start streaming: $e');
        setState(() {
          _isStreaming = false;
        });
      }
    }
  }

  void _stopStreaming() {
    _streamingService.stopDataStreaming();
    setState(() {
      _isStreaming = false;
    });
    showSnackBar(context, 'Stopped data streaming');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Connection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 16),
            _buildWiFiScanSection(),
            const SizedBox(height: 16),
            _buildDataStreamingSection(),
            const SizedBox(height: 16),
            _buildStreamDataDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        statusIcon = Icons.wifi;
        statusColor = Colors.green;
        statusText = 'Connected to WiFi';
        break;
      case ConnectivityResult.mobile:
        statusIcon = Icons.signal_cellular_4_bar;
        statusColor = Colors.orange;
        statusText = 'Connected to Mobile Data';
        break;
      case ConnectivityResult.ethernet:
        statusIcon = Icons.cable;
        statusColor = Colors.blue;
        statusText = 'Connected to Ethernet';
        break;
      default:
        statusIcon = Icons.signal_wifi_off;
        statusColor = Colors.red;
        statusText = 'No Connection';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWiFiScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available WiFi Networks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanForNetworks,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_availableNetworks.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableNetworks.length,
                  itemBuilder: (context, index) {
                    final network = _availableNetworks[index];
                    return ListTile(
                      leading: Icon(
                        Icons.wifi,
                        color: _getSignalStrengthColor(network.level),
                      ),
                      title: Text(network.ssid),
                      subtitle: Text('Signal: ${network.level} dBm'),
                      trailing: network.capabilities.contains('WPA') ||
                              network.capabilities.contains('WEP')
                          ? const Icon(Icons.lock)
                          : const Icon(Icons.lock_open),
                      onTap: () => _showConnectDialog(network),
                    );
                  },
                ),
              )
            else
              const Text('No networks found. Tap "Scan" to search for WiFi networks.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStreamingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Data Streaming',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _streamingEndpointController,
              decoration: const InputDecoration(
                labelText: 'Streaming Endpoint URL',
                hintText: 'http://192.168.1.100:8080/stream',
                border: OutlineInputBorder(),
              ),
              enabled: !_isStreaming,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _connectionStatus == ConnectivityResult.wifi
                  ? (_isStreaming ? _stopStreaming : _startStreaming)
                  : null,
              icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
              label: Text(_isStreaming ? 'Stop Streaming' : 'Start Streaming'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            if (_connectionStatus != ConnectivityResult.wifi)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Connect to WiFi to enable data streaming',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamDataDisplay() {
    return SizedBox(
      height: 300, // Fixed height instead of Expanded
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Streaming Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_streamData.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _streamData.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear data',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _streamData.isEmpty
                      ? const Center(
                          child: Text(
                            'No streaming data\nStart streaming to see data here',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: _streamData.length,
                          itemBuilder: (context, index) {
                            final reversedIndex = _streamData.length - 1 - index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              child: Text(
                                '${DateTime.now().toLocal().toString().substring(11, 19)}: ${_streamData[reversedIndex]}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSignalStrengthColor(int level) {
    if (level >= -50) return Colors.green;
    if (level >= -60) return Colors.orange;
    if (level >= -70) return Colors.red;
    return Colors.grey;
  }

  void _showConnectDialog(WiFiAccessPoint network) {
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connect to ${network.ssid}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Signal Strength: ${network.level} dBm'),
              const SizedBox(height: 16),
              if (network.capabilities.contains('WPA') ||
                  network.capabilities.contains('WEP'))
                Column(
                  children: [
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Due to Android security restrictions, WiFi settings will open for manual connection.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              else
                const Column(
                  children: [
                    Text('This is an open network (no password required)'),
                    SizedBox(height: 8),
                    Text(
                      'WiFi settings will open for manual connection.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _passwordController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isConnecting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _connectToWiFi(network.ssid, _passwordController.text);
                    },
              child: _isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
          ],
        );
      },
    );
  }
}
