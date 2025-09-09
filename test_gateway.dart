import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:logging/logging.dart';

final _logger = Logger('GatewayTest');

void main() async {
  _logger.info('Testing WiFi gateway detection...');

  final networkInfo = NetworkInfo();
  
  try {
    _logger.info('\n--- Current WiFi Information ---');

    final wifiName = await networkInfo.getWifiName();
    _logger.info('WiFi Name: ${wifiName ?? "Not connected"}');

    final wifiBSSID = await networkInfo.getWifiBSSID();
    _logger.info('WiFi BSSID: ${wifiBSSID ?? "Not available"}');

    final wifiIP = await networkInfo.getWifiIP();
    _logger.info('WiFi IP: ${wifiIP ?? "Not available"}');

    final wifiSubmask = await networkInfo.getWifiSubmask();
    _logger.info('WiFi Submask: ${wifiSubmask ?? "Not available"}');

    final wifiGateway = await networkInfo.getWifiGatewayIP();
    _logger.info('WiFi Gateway: ${wifiGateway ?? "Not available"}');

    _logger.info('\n--- Generated Endpoint URLs ---');

    if (wifiGateway != null && wifiGateway.isNotEmpty) {
      final cleanGateway = wifiGateway.replaceAll('"', '').trim();
      final endpointUrl = 'http://$cleanGateway:1234';
      _logger.info('Default endpoint (port 1234): $endpointUrl');
      _logger.info('Alternative endpoint (port 80): http://$cleanGateway');
      _logger.info('Alternative endpoint (port 8080): http://$cleanGateway:8080');
    } else {
      _logger.severe('❌ No gateway detected - cannot generate endpoint URL');
    }

    _logger.info('\n--- Windows Network Commands ---');
    _logger.info('Testing Windows network interface command...');

    // Test netsh command for interface info
    final result = await Process.run(
      'netsh',
      ['interface', 'ip', 'show', 'config'],
      runInShell: true,
    );
    
    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      _logger.info('Network interface info available:');
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.toLowerCase().contains('gateway') || 
            line.toLowerCase().contains('ip address') ||
            line.toLowerCase().contains('wifi')) {
          _logger.info('  $line');
        }
      }
    } else {
      _logger.severe('❌ Failed to get network interface info: ${result.stderr}');
    }
    
  } catch (e) {
    _logger.severe('❌ Error testing gateway detection: $e');
  }
}
