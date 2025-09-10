import 'package:network_info_plus/network_info_plus.dart';
import 'package:logging/logging.dart';

final _logger = Logger('EndpointTest');

void main() async {
  _logger.info('Testing Endpoint URL Generation...');

  final networkInfo = NetworkInfo();

  try {
    _logger.info('=== Current Network Information ===');

    final wifiName = await networkInfo.getWifiName();
    final wifiGateway = await networkInfo.getWifiGatewayIP();

    _logger.info('WiFi Name: ${wifiName ?? "Not connected"}');
    _logger.info('WiFi Gateway: ${wifiGateway ?? "Not available"}');

    _logger.info('=== Endpoint URL Generation Test ===');

    if (wifiGateway != null &&
        wifiGateway.isNotEmpty &&
        wifiGateway != 'null') {
      final cleanGateway = wifiGateway.replaceAll('"', '').trim();
      if (cleanGateway.isNotEmpty && cleanGateway != 'null') {
        final endpointUrl = 'http://$cleanGateway:1234';
        _logger.info('✅ Generated endpoint URL: $endpointUrl');

        // Test other common ports
        _logger.info('Alternative ports:');
        _logger.info('  - http://$cleanGateway (port 80)');
        _logger.info('  - http://$cleanGateway:8080');
        _logger.info('  - http://$cleanGateway:3000');
      } else {
        _logger.warning('❌ Gateway address is empty or null after cleaning');
      }
    } else {
      _logger.severe('❌ No gateway address available');
      _logger.info('   - This could mean:');
      _logger.info('     1. Not connected to WiFi');
      _logger.info('     2. Network adapter issue');
      _logger.info('     3. Permission issue');
      _logger.info('     4. Windows network configuration issue');
    }

    _logger.info('\n=== Troubleshooting Info ===');
    _logger.info('If gateway is not available, try:');
    _logger.info('1. Connect to a WiFi network first');
    _logger.info('2. Run: ipconfig /all (in Command Prompt)');
    _logger.info('3. Check if Default Gateway shows an IP address');
    _logger.info('4. Ensure WiFi adapter is working properly');
  } catch (e) {
    _logger.severe('❌ Error: $e');
  }
}
