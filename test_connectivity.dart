import 'lib/core/windows_wifi_service.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ConnectivityTest');

void main() async {
  final wifiService = WindowsWiFiService();

  _logger.info('Testing Windows connectivity management...');

  try {
    // Test disabling connectivity checking
    _logger.info('1. Disabling network connectivity checking...');
    await wifiService.disableNetworkConnectivityChecking();
    _logger.info('✓ Successfully disabled connectivity checking');

    // Wait a moment
    await Future.delayed(Duration(seconds: 2));

    // Test enabling connectivity checking
    _logger.info('2. Re-enabling network connectivity checking...');
    await wifiService.enableNetworkConnectivityChecking();
    _logger.info('✓ Successfully re-enabled connectivity checking');

    _logger.info('✅ All connectivity management tests passed!');
    _logger.info(
        'Note: Registry changes require administrator privileges to take effect.');
    _logger.info(
        'Run this script as administrator to test the actual registry modifications.');
  } catch (e) {
    _logger.severe('❌ Test failed: $e');
    _logger.warning('This might be expected if not running as administrator.');
  }
}
