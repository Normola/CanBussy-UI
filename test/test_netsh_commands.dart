import 'dart:io';
import 'package:logging/logging.dart';

final _logger = Logger('NetshTest');

void main() async {
  _logger.info('Testing netsh commands for WiFi scanning...\n');

  // Test 1: Check if we can refresh networks
  _logger.info('1. Refreshing WiFi scan...');
  final refreshResult = await Process.run(
    'netsh',
    ['wlan', 'refresh'],
    runInShell: true,
  );
  _logger.info('   Exit code: ${refreshResult.exitCode}');
  if (refreshResult.exitCode != 0) {
    _logger.severe('   Error: ${refreshResult.stderr}');
  }

  // Wait for scan to complete
  await Future.delayed(const Duration(seconds: 2));

  // Test 2: Try to get available networks
  _logger.info('\n2. Scanning for available networks...');
  final networksResult = await Process.run(
    'netsh',
    ['wlan', 'show', 'networks'],
    runInShell: true,
  );
  _logger.info('   Exit code: ${networksResult.exitCode}');
  _logger.info('   Output:');
  _logger.info('${networksResult.stdout}');
  if (networksResult.exitCode != 0) {
    _logger.severe('   Error: ${networksResult.stderr}');
  }

  // Test 3: Try to get available networks with BSSID info
  _logger.info('\n3. Scanning for available networks with BSSID...');
  final bssidResult = await Process.run(
    'netsh',
    ['wlan', 'show', 'networks', 'mode=bssid'],
    runInShell: true,
  );
  _logger.info('   Exit code: ${bssidResult.exitCode}');
  _logger.info('   Output:');
  _logger.info('${bssidResult.stdout}');
  if (bssidResult.exitCode != 0) {
    _logger.severe('   Error: ${bssidResult.stderr}');
  }

  // Test 4: Show saved profiles for comparison
  _logger.info('\n4. Showing saved profiles...');
  final profilesResult = await Process.run(
    'netsh',
    ['wlan', 'show', 'profiles'],
    runInShell: true,
  );
  _logger.info('   Exit code: ${profilesResult.exitCode}');
  _logger.info('   Output:');
  _logger.info('${profilesResult.stdout}');
  if (profilesResult.exitCode != 0) {
    _logger.severe('   Error: ${profilesResult.stderr}');
  }
}
