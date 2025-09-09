import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../core/windows_wifi_service.dart';
import '../core/wifi_service.dart';
import '../core/snackbar.dart';

class WindowsWiFiConnectionScreen extends StatefulWidget {
  const WindowsWiFiConnectionScreen({super.key});

  @override
  State<WindowsWiFiConnectionScreen> createState() => _WindowsWiFiConnectionScreenState();
}

class _WindowsWiFiConnectionScreenState extends State<WindowsWiFiConnectionScreen> {
  late final dynamic _wifiService;
  late final dynamic _streamingService;
  
  List<dynamic> _availableNetworks = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isStreaming = false;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _streamingEndpointController = TextEditingController();
  
  final List<String> _streamData = [];
  Map<String, String?> _currentWiFiInfo = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize platform-specific services
    if (Platform.isWindows) {
      _wifiService = WindowsWiFiService();
      _streamingService = WindowsDataStreamingService();
    } else {
      _wifiService = WiFiService();
      _streamingService = DataStreamingService();
    }
    
    _initializeConnectivity();
    _startConnectivityMonitoring();
    _startDataStreamMonitoring();
    _loadCurrentWiFiInfo();
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
          _loadCurrentWiFiInfo();
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

  Future<void> _loadCurrentWiFiInfo() async {
    if (Platform.isWindows && _connectionStatus == ConnectivityResult.wifi) {
      try {
        final info = await (_wifiService as WindowsWiFiService).getCurrentWiFiInfo();
        if (mounted) {
          setState(() {
            _currentWiFiInfo = info;
          });
          
          // Auto-populate endpoint URL if it's empty and we have a gateway
          if (_streamingEndpointController.text.isEmpty) {
            await _updateEndpointFromGateway();
          }
        }
      } catch (e) {
        // Ignore errors when getting WiFi info
      }
    }
  }

  Future<void> _updateEndpointFromGateway() async {
    if (Platform.isWindows) {
      try {
        final endpointUrl = await (_wifiService as WindowsWiFiService).getEndpointUrlFromGateway();
        if (endpointUrl != null && mounted) {
          setState(() {
            _streamingEndpointController.text = endpointUrl;
          });
        }
      } catch (e) {
        // Ignore errors when getting endpoint URL
      }
    }
  }

  Future<void> _scanForNetworks() async {
    setState(() {
      _isScanning = true;
    });

    try {
      List<dynamic> networks;
      if (Platform.isWindows) {
        networks = await (_wifiService as WindowsWiFiService).scanWiFiNetworks();
      } else {
        networks = await (_wifiService as WiFiService).scanWiFiNetworks();
      }
      
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
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToWiFi(String ssid, String password) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      if (Platform.isWindows) {
        // Use the new method that returns connection status and endpoint URL
        final result = await (_wifiService as WindowsWiFiService).connectToWiFiWithEndpoint(ssid, password);
        
        if (mounted) {
          if (result['connected'] == true) {
            showSnackBar(context, 'Successfully connected to $ssid');
            _passwordController.clear();
            _loadCurrentWiFiInfo();
            
            // Populate the endpoint URL if available
            if (result['endpointUrl'] != null) {
              _streamingEndpointController.text = result['endpointUrl'];
              showSnackBar(context, 'Endpoint URL auto-populated: ${result['endpointUrl']}');
            }
          } else {
            showSnackBar(context, 'Connection attempt made. Check Windows notification area for status.');
            _passwordController.clear();
          }
        }
      } else {
        // For non-Windows platforms, use the original method
        final success = await _wifiService.connectToWiFi(ssid, password);
        if (mounted) {
          if (success) {
            showSnackBar(context, 'Successfully connected to $ssid');
            _passwordController.clear();
            _loadCurrentWiFiInfo();
          } else {
            showSnackBar(context, 'WiFi settings opened. Please connect to $ssid manually.');
            _passwordController.clear();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Connection error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _openWiFiSettings() async {
    try {
      if (Platform.isWindows) {
        // Open Windows WiFi settings using system command
        await Process.run('ms-settings:', ['network-wifi'], runInShell: true);
        if (mounted) {
          showSnackBar(context, 'Windows WiFi settings opened');
        }
      } else {
        // For other platforms, this would open platform-specific settings
        if (mounted) {
          showSnackBar(context, 'WiFi settings feature not available on this platform');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to open WiFi settings: $e');
      }
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

  Future<void> _saveStreamDataToFile() async {
    if (_streamData.isEmpty) {
      showSnackBar(context, 'No data to save');
      return;
    }

    try {
      // Let user choose where to save the file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save streaming data',
        fileName: 'stream_data_${DateTime.now().millisecondsSinceEpoch}.pcap',
        type: FileType.custom,
        allowedExtensions: ['pcap', 'pcapng', 'txt'],
      );

      if (outputFile == null) {
        // User cancelled the picker
        return;
      }

      // Create the file content
      final file = File(outputFile);
      
      if (outputFile.toLowerCase().endsWith('.txt')) {
        // Save as plain text file with timestamps
        final buffer = StringBuffer();
        buffer.writeln('# CanBussy Stream Data Export');
        buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
        buffer.writeln('# Total packets: ${_streamData.length}');
        buffer.writeln('');
        
        for (int i = 0; i < _streamData.length; i++) {
          final timestamp = DateTime.now().subtract(Duration(seconds: _streamData.length - i));
          buffer.writeln('${timestamp.toIso8601String()}: ${_streamData[i]}');
        }
        
        await file.writeAsString(buffer.toString());
      } else {
        // Save as pcap format (simplified version)
        // Note: This creates a basic pcap-like structure
        // For full Wireshark compatibility, you might need a more sophisticated pcap library
        final buffer = StringBuffer();
        
        // Write pcap header comments
        buffer.writeln('# PCAP-like data export from CanBussy');
        buffer.writeln('# Format: timestamp|packet_data');
        buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
        buffer.writeln('');
        
        for (int i = 0; i < _streamData.length; i++) {
          final timestamp = DateTime.now().subtract(Duration(seconds: _streamData.length - i));
          // Format as timestamp|data for easier parsing
          buffer.writeln('${timestamp.millisecondsSinceEpoch}|${_streamData[i]}');
        }
        
        await file.writeAsString(buffer.toString());
      }

      if (mounted) {
        showSnackBar(context, 'Data saved to: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to save file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${Platform.isWindows ? "Windows " : ""}WiFi Connection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (Platform.isWindows)
            IconButton(
              onPressed: _openWiFiSettings,
              icon: const Icon(Icons.settings),
              tooltip: 'Open Windows WiFi Settings',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 16),
            if (Platform.isWindows)
              _buildWindowsConnectivityControls(),
            if (Platform.isWindows)
              const SizedBox(height: 16),
            if (Platform.isWindows && _currentWiFiInfo.isNotEmpty)
              _buildCurrentWiFiInfo(),
            if (Platform.isWindows && _currentWiFiInfo.isNotEmpty)
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
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            if (Platform.isWindows)
              Icon(Icons.computer, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsConnectivityControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Windows Network Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Prevent Windows from auto-disconnecting when no internet is detected (useful for local device connections)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _wifiService.disableNetworkConnectivityChecking();
                        if (mounted) {
                          showSnackBar(
                            context,
                            'Disabled automatic disconnection. Windows will stay connected to networks without internet.',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showSnackBar(
                            context,
                            'Failed to disable connectivity checking: $e',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disable Auto-Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _wifiService.enableNetworkConnectivityChecking();
                        if (mounted) {
                          showSnackBar(
                            context,
                            'Re-enabled automatic disconnection. Windows will disconnect from networks without internet.',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showSnackBar(
                            context,
                            'Failed to enable connectivity checking: $e',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Restore Default'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                border: Border.all(color: Colors.orange, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: These changes may require administrator privileges and will persist until restored.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWiFiInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current WiFi Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._currentWiFiInfo.entries.map((entry) {
              if (entry.value != null && entry.value!.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${entry.key.toUpperCase()}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
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
                Text(
                  '${Platform.isWindows ? "Available " : "Available "}WiFi Networks',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        color: _getSignalStrengthColor(
                          Platform.isWindows 
                            ? (network as WindowsWiFiAccessPoint).signalStrengthDbm
                            : (network as dynamic).level,
                        ),
                      ),
                      title: Text(
                        Platform.isWindows 
                          ? (network as WindowsWiFiAccessPoint).ssid
                          : (network as dynamic).ssid,
                      ),
                      subtitle: Text(
                        Platform.isWindows 
                          ? 'Signal: ${(network as WindowsWiFiAccessPoint).signal} | ${network.authentication}'
                          : 'Signal: ${(network as dynamic).level} dBm',
                      ),
                      trailing: Platform.isWindows
                        ? ((network as WindowsWiFiAccessPoint).authentication.contains('WPA') ||
                           network.authentication.contains('WEP'))
                          ? const Icon(Icons.lock)
                          : const Icon(Icons.lock_open)
                        : ((network as dynamic).capabilities.contains('WPA') ||
                           (network as dynamic).capabilities.contains('WEP'))
                          ? const Icon(Icons.lock)
                          : const Icon(Icons.lock_open),
                      onTap: () => _showConnectDialog(network),
                    );
                  },
                ),
              )
            else
              Text(
                Platform.isWindows 
                  ? 'No networks found. Tap "Scan" to search for available WiFi networks.'
                  : 'No networks found. Tap "Scan" to search for WiFi networks.',
              ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _streamingEndpointController,
                    decoration: const InputDecoration(
                      labelText: 'Streaming Endpoint URL',
                      hintText: 'http://192.168.4.1:1234',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isStreaming,
                  ),
                ),
                const SizedBox(width: 8),
                if (Platform.isWindows && _connectionStatus == ConnectivityResult.wifi)
                  IconButton(
                    onPressed: _updateEndpointFromGateway,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Auto-fill from Gateway',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _connectionStatus != ConnectivityResult.none
                  ? (_isStreaming ? _stopStreaming : _startStreaming)
                  : null,
              icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
              label: Text(_isStreaming ? 'Stop Streaming' : 'Start Streaming'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            if (_connectionStatus == ConnectivityResult.none)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Connect to a network to enable data streaming',
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _saveStreamDataToFile,
                          icon: const Icon(Icons.save),
                          tooltip: 'Save to file',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _streamData.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear data',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
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

  void _showConnectDialog(dynamic network) {
    _passwordController.clear();
    
    final String ssid = Platform.isWindows 
      ? (network as WindowsWiFiAccessPoint).ssid
      : (network as dynamic).ssid;
      
    final bool isSecured = Platform.isWindows
      ? ((network as WindowsWiFiAccessPoint).authentication.contains('WPA') ||
         network.authentication.contains('WEP'))
      : ((network as dynamic).capabilities.contains('WPA') ||
         (network as dynamic).capabilities.contains('WEP'));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connect to $ssid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (Platform.isWindows)
                Text('Type: ${(network as WindowsWiFiAccessPoint).authentication}')
              else
                Text('Signal Strength: ${(network as dynamic).level} dBm'),
              const SizedBox(height: 16),
              if (isSecured)
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
                    if (Platform.isWindows)
                      const Text(
                        'Note: Windows will attempt to connect using the saved profile or create a new one.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      const Text(
                        'Note: Due to Android security restrictions, WiFi settings will open for manual connection.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    const Text('This is an open network (no password required)'),
                    const SizedBox(height: 8),
                    if (Platform.isWindows)
                      const Text(
                        'Windows will attempt to connect automatically.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      const Text(
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
                      _connectToWiFi(ssid, _passwordController.text);
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
