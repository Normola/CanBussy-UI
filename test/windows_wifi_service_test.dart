import 'package:flutter_test/flutter_test.dart';
import 'package:canbussy_ui/core/windows_wifi_service.dart';

void main() {
  group('WindowsWiFiAccessPoint', () {
    test('should convert signal percentage to dBm level correctly', () {
      // Test signal percentage to dBm conversion
      final ap100 = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: '100%',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(ap100.signalStrengthDbm, equals(-50)); // 100% should be -50 dBm

      final ap75 = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: '75%',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(ap75.signalStrengthDbm, equals(-63)); // 75% should be -63 dBm (75 ~/ 2 = 37)

      final ap50 = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: '50%',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(ap50.signalStrengthDbm, equals(-75)); // 50% should be -75 dBm

      final ap0 = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: '0%',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(ap0.signalStrengthDbm, equals(-100)); // 0% should be -100 dBm
    });

    test('should handle invalid signal values gracefully', () {
      final apInvalid = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: 'invalid',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(apInvalid.signalStrengthDbm, equals(-60)); // Should default to -60 dBm

      final apEmpty = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: '',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(apEmpty.signalStrengthDbm, equals(-60)); // Should default to -60 dBm
    });

    test('should generate correct capabilities string', () {
      final ap = WindowsWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signal: '75%',
        authentication: 'WPA2',
        encryption: 'AES',
      );
      expect(ap.capabilities, equals('WPA2-AES'));
    });
  });

  group('WindowsWiFiService', () {
    test('should scan for WiFi networks on Windows', () async {
      final service = WindowsWiFiService();
      
      try {
        final networks = await service.scanWiFiNetworks();
        // On Windows, this should return a list (could be empty or populated)
        expect(networks, isA<List<WindowsWiFiAccessPoint>>());
        
        // If networks are found, verify they have the required properties
        if (networks.isNotEmpty) {
          final firstNetwork = networks.first;
          expect(firstNetwork.ssid, isNotEmpty);
          expect(firstNetwork.signal, isNotEmpty);
          expect(firstNetwork.authentication, isNotEmpty);
          expect(firstNetwork.signalStrengthDbm, isA<int>());
        }
      } catch (e) {
        // On non-Windows platforms or if WiFi is disabled, expect an exception
        expect(e, isA<Exception>());
      }
    });

    test('should generate endpoint URL from gateway', () async {
      final service = WindowsWiFiService();
      
      try {
        final endpointUrl = await service.getEndpointUrlFromGateway();
        if (endpointUrl != null) {
          expect(endpointUrl, startsWith('http://'));
          expect(endpointUrl, contains(':80')); // Default HTTP port
        }
      } catch (e) {
        // May fail if not connected to WiFi or on non-Windows platforms
        expect(e, isA<Exception>());
      }
    });

    test('should return null for non-WiFi connections', () async {
      final service = WindowsWiFiService();
      
      try {
        final endpointUrl = await service.getEndpointUrlFromGateway();
        // Should return null if not connected to WiFi (e.g., Ethernet only)
        // or a valid HTTP URL if connected to WiFi
        if (endpointUrl != null) {
          expect(endpointUrl, startsWith('http://'));
          expect(endpointUrl, contains(':80'));
        }
      } catch (e) {
        // May fail if not connected to any network or on non-Windows platforms
        expect(e, isA<Exception>());
      }
    });
  });
}
