import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _logger = Logger('WindowsWiFiService');

// Data class for WiFi access points
class WindowsWiFiAccessPoint {
  final String ssid;
  final String bssid;
  final String signal;
  final String authentication;
  final String encryption;

  WindowsWiFiAccessPoint({
    required this.ssid,
    required this.bssid,
    required this.signal,
    required this.authentication,
    required this.encryption,
  });

  // Convert signal strength to dBm
  int get signalStrengthDbm {
    try {
      final percentMatch = RegExp(r'(\d+)%').firstMatch(signal);
      if (percentMatch != null) {
        final percent = int.parse(percentMatch.group(1)!);
        // Convert percentage to approximate dBm (-50 to -100 range)
        return -100 + (percent ~/ 2);
      }
      return -60; // Default to -60 dBm
    } catch (e) {
      return -60; // Default to -60 dBm
    }
  }

  String get capabilities {
    return '$authentication-$encryption';
  }
}

class WindowsWiFiService {
  static final WindowsWiFiService _instance = WindowsWiFiService._internal();
  factory WindowsWiFiService() => _instance;
  WindowsWiFiService._internal();

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();

  // Stream to listen to connectivity changes
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream;

  // Check if WiFi permissions are granted (Windows doesn't need special permissions)
  Future<bool> checkWiFiPermissions() async {
    return true;
  }

  // Request WiFi permissions (no-op on Windows)
  Future<bool> requestWiFiPermissions() async {
    return true;
  }

  // Scan for available WiFi networks
  Future<List<WindowsWiFiAccessPoint>> scanWiFiNetworks() async {
    final List<WindowsWiFiAccessPoint> networks = [];

    try {
      // Use netsh to scan for available networks
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'networks', 'mode=bssid'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        _logger.info(
            'Scanning WiFi networks, parsing ${lines.length} lines of output');

        String? currentSSID;
        String? currentBSSID;
        String signal = '50%';
        String authentication = 'Unknown';
        String encryption = 'Unknown';

        for (String line in lines) {
          final trimmedLine = line.trim();

          if (trimmedLine.startsWith('SSID ') && trimmedLine.contains(' : ')) {
            _logger.info('Found SSID line: "$trimmedLine"');

            // Save previous network if we have one
            if (currentSSID != null && currentBSSID != null) {
              _logger.info('Adding network: $currentSSID ($currentBSSID)');
              networks.add(WindowsWiFiAccessPoint(
                ssid: currentSSID,
                bssid: currentBSSID,
                signal: signal,
                authentication: authentication,
                encryption: encryption,
              ));
            }

            // Parse new SSID - handle both named and unnamed (hidden) networks
            final ssidMatch =
                RegExp(r'SSID \d+ : ?(.*)').firstMatch(trimmedLine);
            if (ssidMatch != null) {
              final ssidName = ssidMatch.group(1)?.trim() ?? '';
              if (ssidName.isNotEmpty) {
                currentSSID = ssidName;
                _logger.info('Parsed SSID: "$currentSSID"');
              } else {
                currentSSID =
                    '<Hidden Network>'; // Show hidden networks with a placeholder name
                _logger.info('Found hidden network, using placeholder name');
              }
            } else {
              currentSSID = null;
              _logger.warning('Failed to parse SSID from: "$trimmedLine"');
            }

            // Reset values for new network
            currentBSSID = null;
            signal = '50%';
            authentication = 'Unknown';
            encryption = 'Unknown';
          } else if (trimmedLine.contains('Authentication') &&
              trimmedLine.contains(':')) {
            authentication = trimmedLine.split(':')[1].trim();
            _logger.info('Found authentication: $authentication');
          } else if (trimmedLine.contains('Encryption') &&
              trimmedLine.contains(':')) {
            encryption = trimmedLine.split(':')[1].trim();
            _logger.info('Found encryption: $encryption');
          } else if (trimmedLine.contains('Signal') &&
              trimmedLine.contains(':')) {
            final signalMatch = RegExp(r'(\d+)%').firstMatch(trimmedLine);
            signal = signalMatch != null ? '${signalMatch.group(1)}%' : '50%';
            _logger.info('Found signal: $signal');
          } else if (trimmedLine.contains('Radio type') &&
              trimmedLine.contains(':')) {
            // Radio type info - could be used for additional details
            _logger.info('Found radio type: $trimmedLine');
          } else if (trimmedLine.startsWith('BSSID ') &&
              trimmedLine.contains(':')) {
            // Parse BSSID and additional details - handle variable whitespace
            final bssidMatch = RegExp(r'BSSID \d+\s*:\s*([a-fA-F0-9:]+)')
                .firstMatch(trimmedLine);
            if (bssidMatch != null) {
              currentBSSID = bssidMatch.group(1);
              _logger.info('Found BSSID: $currentBSSID');

              // Check if this line also contains signal info
              final signalMatch = RegExp(r'(\d+)%').firstMatch(trimmedLine);
              if (signalMatch != null) {
                signal = '${signalMatch.group(1)}%';
                _logger.info('Found signal in BSSID line: $signal');
              }
            } else {
              _logger.warning('Failed to parse BSSID from: "$trimmedLine"');
            }
          }
        }

        // Don't forget the last network
        if (currentSSID != null && currentBSSID != null) {
          _logger.info('Adding final network: $currentSSID ($currentBSSID)');
          networks.add(WindowsWiFiAccessPoint(
            ssid: currentSSID,
            bssid: currentBSSID,
            signal: signal,
            authentication: authentication,
            encryption: encryption,
          ));
        }
      }

      // Additional detailed scan for more accurate information
      for (var i = 0; i < networks.length; i++) {
        try {
          final detailResult = await Process.run(
            'netsh',
            [
              'wlan',
              'show',
              'profile',
              'name=${networks[i].ssid}',
              'key=clear'
            ],
            runInShell: true,
          );

          if (detailResult.exitCode == 0) {
            final detailOutput = detailResult.stdout.toString();
            final detailLines = detailOutput.split('\n');

            for (String detailLine in detailLines) {
              final trimmedDetailLine = detailLine.trim();
              if (trimmedDetailLine.contains('Authentication')) {
                // Update authentication if found
              } else if (trimmedDetailLine.contains('Cipher')) {
                // Update cipher info if found
              }
            }
          }
        } catch (e) {
          // Ignore errors for individual networks
          continue;
        }
      }
    } catch (e) {
      _logger.severe('Error scanning WiFi networks: $e');
    }

    _logger.info('Successfully parsed ${networks.length} WiFi networks');
    return networks;
  }

  // Get WiFi networks that are saved/configured
  Future<List<String>> getSavedNetworks() async {
    final List<String> networks = [];

    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'profile'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        _logger.info('Parsing netsh output, total lines: ${lines.length}');

        for (String line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('All User Profile') &&
              trimmedLine.contains(':')) {
            final parts = trimmedLine.split(':');
            if (parts.length > 1) {
              final networkName = parts[1].trim();
              if (networkName.isNotEmpty) {
                networks.add(networkName);
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.severe('Error getting saved networks: $e');
    }

    return networks;
  }

  // Connect to a WiFi network
  Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      // Check if profile already exists
      if (await _checkProfileExists(ssid)) {
        // Try to connect directly
        final connectResult = await Process.run(
          'netsh',
          ['wlan', 'connect', 'name=$ssid'],
          runInShell: true,
        );

        if (connectResult.exitCode == 0) {
          return true;
        }
      }

      // Create new profile if it doesn't exist or connection failed
      await _createWiFiProfile(ssid, password);

      // Wait a moment for profile to be created
      await Future.delayed(const Duration(seconds: 2));

      // Now try to connect
      final connectResult = await Process.run(
        'netsh',
        ['wlan', 'connect', 'name=$ssid'],
        runInShell: true,
      );

      if (connectResult.exitCode == 0) {
        // Wait for connection to establish
        await Future.delayed(const Duration(seconds: 3));
        return true;
      } else {
        _logger.warning('Failed to connect to $ssid: ${connectResult.stderr}');
        return false;
      }
    } catch (e) {
      _logger.severe('Error connecting to WiFi: $e');
      return false;
    }
  }

  // Disconnect from current WiFi
  Future<bool> disconnectFromWiFi() async {
    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'disconnect'],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      _logger.severe('Error disconnecting from WiFi: $e');
      return false;
    }
  }

  // Connect to WiFi and get endpoint URL
  Future<Map<String, dynamic>> connectToWiFiWithEndpoint(
      String ssid, String password,
      {int port = 1234}) async {
    try {
      _logger.info('Connecting to WiFi: $ssid and getting endpoint URL...');
      final connected = await connectToWiFi(ssid, password);

      if (connected) {
        _logger.info(
            'WiFi connection successful, waiting for network to stabilize...');
        // Wait a bit more for network to stabilize after connection
        await Future.delayed(const Duration(seconds: 3));

        // Get the endpoint URL from gateway
        _logger.info('Getting endpoint URL from gateway...');
        final endpointUrl = await getEndpointUrlFromGateway();

        _logger.info(
            'Connection result - connected: true, endpointUrl: $endpointUrl');
        return {
          'connected': true,
          'endpointUrl': endpointUrl,
        };
      } else {
        _logger.warning('WiFi connection failed');
        return {
          'connected': false,
          'endpointUrl': null,
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

  // Check if a WiFi profile exists
  Future<bool> _checkProfileExists(String ssid) async {
    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'profile', ssid],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Helper method to create WiFi profile
  Future<void> _createWiFiProfile(String ssid, String password) async {
    // Create XML profile content
    final profileXml = '''<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>''';

    // Create temporary file
    final tempDir = Directory.systemTemp;
    final profileFile = File('${tempDir.path}\\${ssid}_profile.xml');
    await profileFile.writeAsString(profileXml);

    try {
      // Add the profile using netsh
      final result = await Process.run(
        'netsh',
        ['wlan', 'add', 'profile', 'filename=${profileFile.path}'],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to create WiFi profile: ${result.stderr}');
      }
    } finally {
      // Clean up temporary file
      if (await profileFile.exists()) {
        await profileFile.delete();
      }
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
      final wifiBSSID = await _networkInfo.getWifiBSSID();
      final wifiIPv4 = await _networkInfo.getWifiIP();
      final wifiGateway = await _networkInfo.getWifiGatewayIP();
      final wifiSubmask = await _networkInfo.getWifiSubmask();

      return {
        'ssid': wifiName,
        'bssid': wifiBSSID,
        'ipAddress': wifiIPv4,
        'gateway': wifiGateway,
        'subnet': wifiSubmask,
      };
    } catch (e) {
      return {};
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

  // Get endpoint URL from WiFi gateway (ignores Ethernet connections)
  Future<String?> getEndpointUrlFromGateway() async {
    try {
      _logger.info('Getting endpoint URL from gateway...');
      final connectivity = await getCurrentConnectivity();
      _logger.info('Current connectivity: $connectivity');

      // Remove the WiFi-only restriction - check for active WiFi adapter regardless
      // if (connectivity != ConnectivityResult.wifi) {
      //   _logger.warning('Not connected to WiFi, cannot get endpoint URL');
      //   return null; // Only process WiFi connections, ignore Ethernet
      // }

      _logger.info('Running ipconfig to get gateway information...');
      final result = await Process.run('ipconfig', []);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        bool isWifiAdapter = false;
        bool wifiAdapterHasIP = false;
        _logger.info('Parsing ipconfig output, found ${lines.length} lines');

        for (String line in lines) {
          final trimmedLine = line.trim();

          // Check for adapter name
          if (trimmedLine.contains('adapter') && trimmedLine.endsWith(':')) {
            // Reset flags for new adapter
            isWifiAdapter = false;
            wifiAdapterHasIP = false;

            // Check if it's a WiFi adapter (contains "Wi-Fi", "Wireless", or "WiFi")
            isWifiAdapter = trimmedLine.toLowerCase().contains('wi-fi') ||
                trimmedLine.toLowerCase().contains('wireless') ||
                trimmedLine.toLowerCase().contains('wifi');
            _logger.info('Found adapter: $trimmedLine, isWiFi: $isWifiAdapter');
          }

          // Check if this WiFi adapter is active (has an IPv4 address)
          if (isWifiAdapter && trimmedLine.startsWith('IPv4 Address')) {
            wifiAdapterHasIP = true;
            _logger.info(
                'WiFi adapter is active (has IPv4 address): $trimmedLine');
          }

          // Only process gateway for active WiFi adapters
          if (isWifiAdapter &&
              wifiAdapterHasIP &&
              trimmedLine.startsWith('Default Gateway')) {
            final parts = trimmedLine.split(':');
            if (parts.length > 1) {
              final gateway = parts[1].trim();
              _logger.info('Found gateway: "$gateway"');
              if (gateway.isNotEmpty && gateway != '::') {
                final endpointUrl = 'http://$gateway:1234';
                _logger.info('Generated endpoint URL: $endpointUrl');
                return endpointUrl; // Default HTTP endpoint
              }
            }
          }
        }
        _logger.warning('No suitable gateway found in ipconfig output');
      } else {
        _logger.severe(
            'ipconfig command failed with exit code: ${result.exitCode}');
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting endpoint URL from gateway: $e');
      return null;
    }
  }

  // Disable Windows Network Connectivity Status Indicator (NCSI) checking
  Future<void> disableNetworkConnectivityChecking() async {
    try {
      // Disable NCSI active probes
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\NlaSvc\\Parameters\\Internet',
        '/v',
        'EnableActiveProbing',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);

      // Disable NCSI passive polling
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\NlaSvc\\Parameters\\Internet',
        '/v',
        'PassivePolling',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);

      _logger.info('Network connectivity checking disabled');
    } catch (e) {
      _logger.severe('Error disabling network connectivity checking: $e');
    }
  }

  // Re-enable Windows Network Connectivity Status Indicator (NCSI) checking
  Future<void> enableNetworkConnectivityChecking() async {
    try {
      // Enable NCSI active probes
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\NlaSvc\\Parameters\\Internet',
        '/v',
        'EnableActiveProbing',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);

      // Enable NCSI passive polling
      await Process.run('reg', [
        'add',
        'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\NlaSvc\\Parameters\\Internet',
        '/v',
        'PassivePolling',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);

      _logger.info('Network connectivity checking enabled');
    } catch (e) {
      _logger.severe('Error enabling network connectivity checking: $e');
    }
  }
}

// Data streaming service (same as mobile, works cross-platform)
class WindowsDataStreamingService {
  static final WindowsDataStreamingService _instance =
      WindowsDataStreamingService._internal();
  factory WindowsDataStreamingService() => _instance;
  WindowsDataStreamingService._internal();

  StreamSubscription<String>? _dataStreamSubscription;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  // Stream to listen to incoming data
  Stream<String> get dataStream => _dataController.stream;

  // Start streaming data from a network endpoint
  Future<void> startDataStreaming(String endpoint) async {
    try {
      // Check if we're connected to a network
      final wifiService = WindowsWiFiService();
      final connectivity = await wifiService.getCurrentConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw Exception('Not connected to any network');
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
            _dataController.addError(error);
          },
          onDone: () {
            // Stream completed
          },
        );
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: Failed to connect to endpoint');
      }
    } catch (e) {
      _dataController.addError(e);
    }
  }

  // Stop streaming data
  Future<void> stopDataStreaming() async {
    await _dataStreamSubscription?.cancel();
    _dataStreamSubscription = null;
  }

  // Send data to endpoint
  Future<bool> sendData(String endpoint, Map<String, dynamic> data) async {
    try {
      // Check if we're connected to a network
      final wifiService = WindowsWiFiService();
      final connectivity = await wifiService.getCurrentConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw Exception('Not connected to any network');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // Get network status
  Future<bool> isConnectedToNetwork() async {
    try {
      final wifiService = WindowsWiFiService();
      final connectivity = await wifiService.getCurrentConnectivity();
      return connectivity != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Enable NCSI bypass before connecting
  Future<void> enableConnectivityBypass() async {
    final wifiService = WindowsWiFiService();
    await wifiService.disableNetworkConnectivityChecking();
  }

  // Disable NCSI bypass after disconnecting
  Future<void> disableConnectivityBypass() async {
    final wifiService = WindowsWiFiService();
    await wifiService.enableNetworkConnectivityChecking();
  }

  // Dispose resources
  void dispose() {
    stopDataStreaming();
    _dataController.close();
  }
}
