import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _logger = Logger('AndroidWiFiService');

// Data class for WiFi access points
class AndroidWiFiAccessPoint {
  final String ssid;
  final String bssid;
  final int signalLevel;
  final String security;
  final int frequency;

  AndroidWiFiAccessPoint({
    required this.ssid,
    required this.bssid,
    required this.signalLevel,
    required this.security,
    required this.frequency,
  });

  @override
  String toString() {
    return 'AndroidWiFiAccessPoint(ssid: $ssid, bssid: $bssid, signal: $signalLevel dBm, security: $security, frequency: $frequency MHz)';
  }
}

class AndroidDataStreamingService {
  static final AndroidDataStreamingService _instance = AndroidDataStreamingService._internal();
  factory AndroidDataStreamingService() => _instance;
  AndroidDataStreamingService._internal();

  final StreamController<String> _dataController = StreamController<String>.broadcast();
  Timer? _streamingTimer;
  bool _isStreaming = false;

  Stream<String> get dataStream => _dataController.stream;

  Future<void> startDataStreaming(String endpoint) async {
    if (_isStreaming) {
      stopDataStreaming();
    }

    _isStreaming = true;
    _logger.info('Starting data streaming from: $endpoint');

    // Start periodic data streaming
    _streamingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isStreaming) {
        timer.cancel();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Accept': 'application/json', 'User-Agent': 'CanBussy-Android'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final data = 'HTTP ${response.statusCode} - ${response.body.length} bytes - $timestamp';
          _dataController.add(data);
        } else {
          _dataController.add('HTTP Error ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        _dataController.add('Stream Error: $e');
        _logger.warning('Streaming error: $e');
      }
    });
  }

  void stopDataStreaming() {
    _isStreaming = false;
    _streamingTimer?.cancel();
    _streamingTimer = null;
    _logger.info('Data streaming stopped');
  }

  bool get isStreaming => _isStreaming;
}

class AndroidWiFiService {
  static final AndroidWiFiService _instance = AndroidWiFiService._internal();
  factory AndroidWiFiService() => _instance;
  AndroidWiFiService._internal();

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();

  // Stream to listen to connectivity changes
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream;

  // Check if WiFi permissions are granted
  Future<bool> checkWiFiPermissions() async {
    if (!Platform.isAndroid) return true;

    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        _logger.warning('Permission $permission is denied');
        return false;
      }
    }
    return true;
  }

  // Request WiFi permissions
  Future<bool> requestWiFiPermissions() async {
    if (!Platform.isAndroid) return true;

    _logger.info('Requesting WiFi permissions...');

    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    final results = await permissions.request();
    
    for (final permission in permissions) {
      final status = results[permission];
      if (status != null && !status.isGranted) {
        _logger.severe('Permission $permission was denied');
        return false;
      }
    }

    _logger.info('All WiFi permissions granted');
    return true;
  }

  // Scan for available WiFi networks
  Future<List<AndroidWiFiAccessPoint>> scanWiFiNetworks() async {
    try {
      _logger.info('Starting WiFi network scan...');

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
      _logger.info('Can get scanned results: $canGetScannedResults');
      
      if (canGetScannedResults != CanGetScannedResults.yes) {
        throw Exception('WiFi scanning not supported: $canGetScannedResults');
      }

      // Start WiFi scan
      final canStartScan = await WiFiScan.instance.canStartScan();
      _logger.info('Can start scan: $canStartScan');
      
      if (canStartScan == CanStartScan.yes) {
        final result = await WiFiScan.instance.startScan();
        if (!result) {
          throw Exception('Failed to start WiFi scan');
        }
        _logger.info('WiFi scan started, waiting for results...');

        // Wait for scan to complete
        await Future.delayed(const Duration(seconds: 4));
      }

      // Get scan results
      final accessPoints = await WiFiScan.instance.getScannedResults();
      _logger.info('Found ${accessPoints.length} WiFi networks');

      // Convert to our Android-specific format
      final androidAccessPoints = accessPoints.map((ap) {
        return AndroidWiFiAccessPoint(
          ssid: ap.ssid.isNotEmpty ? ap.ssid : '<Hidden Network>',
          bssid: ap.bssid,
          signalLevel: ap.level,
          security: _getSecurityString(ap.capabilities),
          frequency: ap.frequency,
        );
      }).toList();

      // Sort by signal strength (strongest first)
      androidAccessPoints.sort((a, b) => b.signalLevel.compareTo(a.signalLevel));

      _logger.info('Successfully parsed ${androidAccessPoints.length} WiFi networks');
      return androidAccessPoints;
    } catch (e) {
      _logger.severe('Failed to scan WiFi networks: $e');
      throw Exception('Failed to scan WiFi networks: $e');
    }
  }

  String _getSecurityString(String capabilities) {
    if (capabilities.contains('WPA3')) return 'WPA3';
    if (capabilities.contains('WPA2')) return 'WPA2';
    if (capabilities.contains('WPA')) return 'WPA';
    if (capabilities.contains('WEP')) return 'WEP';
    return 'Open';
  }

  // Connect to a WiFi network (opens Android WiFi settings)
  Future<Map<String, dynamic>> connectToWiFiWithEndpoint(String ssid, String password) async {
    try {
      _logger.info('Attempting to connect to WiFi: $ssid');

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
      // and guide the user to connect manually
      await openWiFiSettings();

      // Wait a moment and check if we're connected
      await Future.delayed(const Duration(seconds: 3));
      
      final connectivity = await getCurrentConnectivity();
      if (connectivity == ConnectivityResult.wifi) {
        _logger.info('Connected to WiFi successfully');
        
        // Try to get endpoint URL from gateway
        final endpointUrl = await getEndpointUrlFromGateway();
        
        return {
          'connected': true,
          'endpointUrl': endpointUrl,
          'message': 'WiFi connection detected. Please ensure you connected to $ssid manually.',
        };
      } else {
        return {
          'connected': false,
          'endpointUrl': null,
          'message': 'Please connect to $ssid manually in WiFi settings and try again.',
        };
      }
    } catch (e) {
      _logger.severe('Error in connectToWiFiWithEndpoint: $e');
      return {
        'connected': false,
        'endpointUrl': null,
        'error': e.toString(),
      };
    }
  }

  // Open Android WiFi settings
  Future<void> openWiFiSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.WIFI_SETTINGS',
      );
      await intent.launch();
      _logger.info('Opened WiFi settings');
    } catch (e) {
      _logger.severe('Failed to open WiFi settings: $e');
      throw Exception('Failed to open WiFi settings: $e');
    }
  }

  // Get endpoint URL from gateway
  Future<String?> getEndpointUrlFromGateway() async {
    try {
      _logger.info('Getting endpoint URL from gateway...');
      
      final connectivity = await getCurrentConnectivity();
      _logger.info('Current connectivity: $connectivity');
      
      if (connectivity != ConnectivityResult.wifi) {
        _logger.warning('Not connected to WiFi, cannot get endpoint URL');
        return null;
      }

      // Get gateway IP using network_info_plus
      final gatewayIP = await _networkInfo.getWifiGatewayIP();
      _logger.info('Gateway IP from network_info_plus: $gatewayIP');

      if (gatewayIP != null && gatewayIP.isNotEmpty && gatewayIP != 'null') {
        final cleanGateway = gatewayIP.replaceAll('"', '').trim();
        if (cleanGateway.isNotEmpty && cleanGateway != 'null') {
          final endpointUrl = 'http://$cleanGateway:80';
          _logger.info('Generated endpoint URL: $endpointUrl');
          return endpointUrl;
        }
      }

      _logger.warning('No suitable gateway found');
      return null;
    } catch (e) {
      _logger.severe('Error getting endpoint URL from gateway: $e');
      return null;
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

  // Get current WiFi information
  Future<Map<String, String?>> getCurrentWiFiInfo() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final wifiIP = await _networkInfo.getWifiIP();
      final wifiGateway = await _networkInfo.getWifiGatewayIP();
      final wifiBSSID = await _networkInfo.getWifiBSSID();

      return {
        'name': wifiName?.replaceAll('"', ''),
        'ip': wifiIP,
        'gateway': wifiGateway,
        'bssid': wifiBSSID,
      };
    } catch (e) {
      _logger.severe('Error getting WiFi info: $e');
      return {};
    }
  }

  // Start monitoring connectivity changes
  void startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _connectivityController.add(result);
        _logger.info('Connectivity changed: $result');
      },
    );
    _logger.info('Started connectivity monitoring');
  }

  // Stop monitoring connectivity changes
  void stopConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _logger.info('Stopped connectivity monitoring');
  }

  // Enable network connectivity checking
  Future<void> enableNetworkConnectivityChecking() async {
    _logger.info('Network connectivity checking enabled (Android)');
    // Note: Android handles this automatically through the system
  }

  // Disable network connectivity checking
  Future<void> disableNetworkConnectivityChecking() async {
    _logger.info('Network connectivity checking disabled (Android)');
    // Note: Android handles this automatically through the system
  }
}
