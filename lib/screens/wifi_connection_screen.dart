import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import '../core/android_wifi_service.dart';
import '../core/snackbar.dart';

class WiFiConnectionScreen extends StatefulWidget {
  const WiFiConnectionScreen({super.key});

  @override
  State<WiFiConnectionScreen> createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  final AndroidWiFiService _wifiService = AndroidWiFiService();
  final AndroidDataStreamingService _streamingService =
      AndroidDataStreamingService();
  final Logger _logger = Logger('WiFiConnectionScreen');

  List<AndroidWiFiAccessPoint> _availableNetworks = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isStreaming = false;
  DetailedConnectivityStatus _detailedConnectionStatus =
      DetailedConnectivityStatus.none;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _streamingEndpointController =
      TextEditingController();

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
    final detailedStatus = await _wifiService.getDetailedConnectivityStatus();
    if (mounted) {
      setState(() {
        _detailedConnectionStatus = detailedStatus;
      });
    }
  }

  void _startConnectivityMonitoring() {
    _wifiService.startConnectivityMonitoring();
    _wifiService.detailedConnectivityStream
        .listen((DetailedConnectivityStatus detailedStatus) async {
      if (mounted) {
        setState(() {
          _detailedConnectionStatus = detailedStatus;
        });

        // If connected to WiFi (with or without internet), try to get endpoint URL
        if (detailedStatus == DetailedConnectivityStatus.wifiWithInternet ||
            detailedStatus == DetailedConnectivityStatus.wifiNoInternet) {
          final endpointUrl = await _wifiService.getEndpointUrlFromGateway();
          if (endpointUrl != null &&
              _streamingEndpointController.text.isEmpty) {
            setState(() {
              _streamingEndpointController.text = endpointUrl;
            });
          }
        }

        // Show appropriate messages (WiFi only)
        if (mounted) {
          switch (detailedStatus) {
            case DetailedConnectivityStatus.wifiWithInternet:
              showSnackBar(context, 'Connected to WiFi with internet access');
              break;
            case DetailedConnectivityStatus.wifiNoInternet:
              showSnackBar(context, 'Connected to WiFi but no internet access');
              break;
            case DetailedConnectivityStatus.none:
              showSnackBar(context, 'No WiFi connection');
              break;
            default:
              break;
          }
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

  // Manually refresh connection status and endpoint URL
  Future<void> _refreshConnectionStatus() async {
    try {
      // Debug: Show raw WiFi info
      final wifiInfo = await _wifiService.getCurrentWiFiInfo();
      _logger.info('Debug - WiFi Info: $wifiInfo');

      final detailedStatus = await _wifiService.getDetailedConnectivityStatus();
      setState(() {
        _detailedConnectionStatus = detailedStatus;
      });

      // Show current status for debugging
      if (mounted) {
        String statusMessage = '';
        switch (detailedStatus) {
          case DetailedConnectivityStatus.wifiWithInternet:
            statusMessage = 'Status: WiFi with internet';
            break;
          case DetailedConnectivityStatus.wifiNoInternet:
            statusMessage = 'Status: WiFi without internet';
            break;
          case DetailedConnectivityStatus.mobile:
            statusMessage = 'Status: Mobile data';
            break;
          case DetailedConnectivityStatus.ethernet:
            statusMessage = 'Status: Ethernet';
            break;
          case DetailedConnectivityStatus.none:
            statusMessage = 'Status: No connection';
            break;
        }

        // Add WiFi name to status if available
        final wifiName = wifiInfo['name'];
        if (wifiName != null && wifiName.isNotEmpty) {
          statusMessage += ' (WiFi: $wifiName)';
        }

        showSnackBar(context, statusMessage);
      }

      // If connected to WiFi (with or without internet), get endpoint URL
      if (detailedStatus == DetailedConnectivityStatus.wifiWithInternet ||
          detailedStatus == DetailedConnectivityStatus.wifiNoInternet) {
        final endpointUrl = await _wifiService.getEndpointUrlFromGateway();
        if (endpointUrl != null) {
          setState(() {
            _streamingEndpointController.text = endpointUrl;
          });
          if (mounted) {
            showSnackBar(context, 'Endpoint URL updated: $endpointUrl');
          }
        } else {
          if (mounted) {
            showSnackBar(
                context, 'Could not determine endpoint URL from gateway');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error refreshing connection status: $e');
      }
    }
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
      final result =
          await _wifiService.connectToWiFiWithEndpoint(ssid, password);
      if (mounted) {
        if (result['connected'] == true) {
          showSnackBar(context, 'Successfully connected to $ssid');
          _passwordController.clear();

          // Set endpoint URL if available
          if (result['endpointUrl'] != null) {
            _streamingEndpointController.text = result['endpointUrl'];
          }

          // Refresh detailed connectivity status after connection
          final detailedStatus =
              await _wifiService.getDetailedConnectivityStatus();
          setState(() {
            _detailedConnectionStatus = detailedStatus;
          });

          // Show internet status
          if (result['hasInternet'] == false && mounted) {
            showSnackBar(
                context, 'Connected to WiFi but no internet access detected');
          }
        } else {
          // Manual connection required
          showSnackBar(
              context,
              result['message'] ??
                  'WiFi settings opened. Please connect to $ssid manually.');
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

    switch (_detailedConnectionStatus) {
      case DetailedConnectivityStatus.wifiWithInternet:
        statusIcon = Icons.wifi;
        statusColor = Colors.green;
        statusText = 'Connected to WiFi (Internet)';
        break;
      case DetailedConnectivityStatus.wifiNoInternet:
        statusIcon = Icons.wifi_off;
        statusColor = Colors.orange;
        statusText = 'Connected to WiFi (No Internet)';
        break;
      case DetailedConnectivityStatus.ethernet:
        statusIcon = Icons.cable;
        statusColor = Colors.blue;
        statusText = 'Connected to Ethernet';
        break;
      default:
        statusIcon = Icons.signal_wifi_off;
        statusColor = Colors.red;
        statusText = 'No WiFi Connection';
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
            IconButton(
              onPressed: _refreshConnectionStatus,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh connection status and endpoint',
              color: Colors.blue,
            ),
            IconButton(
              onPressed: () async {
                await _wifiService.debugConnectivityStatus();
                if (mounted) {
                  showSnackBar(context, 'Debug info logged - check console');
                }
              },
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug connectivity status',
              color: Colors.orange,
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
                        color: _getSignalStrengthColor(network.signalLevel),
                      ),
                      title: Text(network.ssid),
                      subtitle: Text(
                          'Signal: ${network.signalLevel} dBm | ${network.security}'),
                      trailing: network.security != 'Open'
                          ? const Icon(Icons.lock)
                          : const Icon(Icons.lock_open),
                      onTap: () => _showConnectDialog(network),
                    );
                  },
                ),
              )
            else
              const Text(
                  'No networks found. Tap "Scan" to search for WiFi networks.'),
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
              onPressed: (_detailedConnectionStatus ==
                          DetailedConnectivityStatus.wifiWithInternet ||
                      _detailedConnectionStatus ==
                          DetailedConnectivityStatus.wifiNoInternet)
                  ? (_isStreaming ? _stopStreaming : _startStreaming)
                  : null,
              icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
              label: Text(_isStreaming ? 'Stop Streaming' : 'Start Streaming'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            if (_detailedConnectionStatus !=
                    DetailedConnectivityStatus.wifiWithInternet &&
                _detailedConnectionStatus !=
                    DetailedConnectivityStatus.wifiNoInternet)
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
                  if (_streamData.isNotEmpty) ...[
                    IconButton(
                      onPressed: _saveStreamDataToFile,
                      icon: const Icon(Icons.save),
                      tooltip: 'Save to file',
                    ),
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
                            final reversedIndex =
                                _streamData.length - 1 - index;
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

  void _showConnectDialog(AndroidWiFiAccessPoint network) {
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connect to ${network.ssid}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Signal Strength: ${network.signalLevel} dBm'),
              Text('Security: ${network.security}'),
              Text('BSSID: ${network.bssid}'),
              const SizedBox(height: 16),
              if (network.security != 'Open')
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

  Future<void> _saveStreamDataToFile() async {
    if (_streamData.isEmpty) {
      showSnackBar(context, 'No data to save');
      return;
    }

    try {
      // Get directory to save file
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) {
        return; // User cancelled
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'canbussy_android_stream_$timestamp.txt';
      final filePath = '$directoryPath/$filename';

      // Create file content
      final fileContent = StringBuffer();
      fileContent.writeln('CanBussy Android Stream Data');
      fileContent.writeln('Generated: ${DateTime.now().toLocal()}');
      fileContent.writeln('Total entries: ${_streamData.length}');
      fileContent.writeln('');

      for (int i = 0; i < _streamData.length; i++) {
        fileContent.writeln('Entry ${i + 1}: ${_streamData[i]}');
      }

      // Write to file
      final file = File(filePath);
      await file.writeAsString(fileContent.toString());

      if (mounted) {
        showSnackBar(context, 'Stream data saved to: $filename');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error saving file: $e');
      }
    }
  }
}
