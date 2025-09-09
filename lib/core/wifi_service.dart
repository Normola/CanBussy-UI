import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;

class WiFiService {
  static final WiFiService _instance = WiFiService._internal();
  factory WiFiService() => _instance;
  WiFiService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();

  // Stream to listen to connectivity changes
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream;

  // Check if WiFi permissions are granted
  Future<bool> checkWiFiPermissions() async {
    if (Platform.isAndroid) {
      final locationPermission = await Permission.location.status;
      final locationAlwaysPermission = await Permission.locationAlways.status;
      
      if (locationPermission.isDenied || locationAlwaysPermission.isDenied) {
        return false;
      }
    }
    return true;
  }

  // Request WiFi permissions
  Future<bool> requestWiFiPermissions() async {
    if (Platform.isAndroid) {
      final locationPermission = await Permission.location.request();
      final locationAlwaysPermission = await Permission.locationAlways.request();
      
      return locationPermission.isGranted && locationAlwaysPermission.isGranted;
    }
    return true;
  }

  // Scan for available WiFi networks
  Future<List<WiFiAccessPoint>> scanWiFiNetworks() async {
    try {
      // Check permissions first
      final hasPermissions = await checkWiFiPermissions();
      if (!hasPermissions) {
        final granted = await requestWiFiPermissions();
        if (!granted) {
          throw Exception('WiFi permissions not granted');
        }
      }

      // Check if WiFi scan is supported
      final canGetScannedResults = await WiFiScan.instance.canGetScannedResults();
      if (canGetScannedResults != CanGetScannedResults.yes) {
        throw Exception('WiFi scanning not supported on this device');
      }

      // Start WiFi scan
      final canStartScan = await WiFiScan.instance.canStartScan();
      if (canStartScan == CanStartScan.yes) {
        final result = await WiFiScan.instance.startScan();
        if (!result) {
          throw Exception('Failed to start WiFi scan');
        }

        // Wait a bit for scan to complete
        await Future.delayed(const Duration(seconds: 3));
      }

      // Get scan results
      final accessPoints = await WiFiScan.instance.getScannedResults();
      return accessPoints;
    } catch (e) {
      throw Exception('Failed to scan WiFi networks: $e');
    }
  }

  // Connect to a WiFi network (opens settings for manual connection)
  Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      // Check permissions first
      final hasPermissions = await checkWiFiPermissions();
      if (!hasPermissions) {
        final granted = await requestWiFiPermissions();
        if (!granted) {
          throw Exception('WiFi permissions not granted');
        }
      }

      // Due to Android security restrictions (API 29+), apps can no longer
      // programmatically connect to WiFi networks. We'll open the WiFi settings
      // and let the user connect manually.
      
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.settings.WIFI_SETTINGS',
        );
        await intent.launch();
      }
      
      // Return false to indicate manual connection is required
      // The UI should inform the user to connect manually
      return false;
      
    } catch (e) {
      throw Exception('Failed to open WiFi settings: $e');
    }
  }

  // Get current connectivity status
  Future<ConnectivityResult> getCurrentConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else {
      return ConnectivityResult.none;
    }
  }

  // Start monitoring connectivity changes
  void startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        ConnectivityResult primaryResult = ConnectivityResult.none;
        
        if (results.contains(ConnectivityResult.wifi)) {
          primaryResult = ConnectivityResult.wifi;
        } else if (results.contains(ConnectivityResult.mobile)) {
          primaryResult = ConnectivityResult.mobile;
        } else if (results.contains(ConnectivityResult.ethernet)) {
          primaryResult = ConnectivityResult.ethernet;
        }
        
        _connectivityController.add(primaryResult);
      },
    );
  }

  // Stop monitoring connectivity changes
  void stopConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // Dispose resources
  void dispose() {
    stopConnectivityMonitoring();
    _connectivityController.close();
  }
}

// Data streaming service
class DataStreamingService {
  static final DataStreamingService _instance = DataStreamingService._internal();
  factory DataStreamingService() => _instance;
  DataStreamingService._internal();

  StreamSubscription<String>? _dataStreamSubscription;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  // Stream to listen to incoming data
  Stream<String> get dataStream => _dataController.stream;

  // Start streaming data from a network endpoint
  Future<void> startDataStreaming(String endpoint) async {
    try {
      // Check if we're connected to WiFi
      final connectivity = await WiFiService().getCurrentConnectivity();
      if (connectivity != ConnectivityResult.wifi) {
        throw Exception('Not connected to WiFi');
      }

      // Start streaming data using HTTP
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(endpoint));
      
      final response = await client.send(request);
      
      if (response.statusCode == 200) {
        _dataStreamSubscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (String data) {
                _dataController.add(data);
              },
              onError: (error) {
                _dataController.addError('Streaming error: $error');
              },
              onDone: () {
                _dataController.add('Stream ended');
              },
            );
      } else {
        throw Exception('Failed to connect to streaming endpoint: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to start data streaming: $e');
    }
  }

  // Stop data streaming
  void stopDataStreaming() {
    _dataStreamSubscription?.cancel();
    _dataStreamSubscription = null;
  }

  // Send data to the network endpoint
  Future<bool> sendData(String endpoint, Map<String, dynamic> data) async {
    try {
      // Check if we're connected to WiFi
      final connectivity = await WiFiService().getCurrentConnectivity();
      if (connectivity != ConnectivityResult.wifi) {
        throw Exception('Not connected to WiFi');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  // Dispose resources
  void dispose() {
    stopDataStreaming();
    _dataController.close();
  }
}
