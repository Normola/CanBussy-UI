// Simple test script to verify Android WiFi functionality
import 'package:flutter_test/flutter_test.dart';
import 'package:canbussy_ui/core/android_wifi_service.dart';

void main() {
  group('AndroidWiFiService Tests', () {
    test('AndroidWiFiService singleton pattern works', () {
      final service1 = AndroidWiFiService();
      final service2 = AndroidWiFiService();
      expect(service1, equals(service2));
    });

    test('AndroidDataStreamingService singleton pattern works', () {
      final service1 = AndroidDataStreamingService();
      final service2 = AndroidDataStreamingService();
      expect(service1, equals(service2));
    });

    test('AndroidWiFiAccessPoint data class works', () {
      final accessPoint = AndroidWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signalLevel: -45,
        security: 'WPA2',
        frequency: 2437,
      );

      expect(accessPoint.ssid, equals('TestNetwork'));
      expect(accessPoint.bssid, equals('00:11:22:33:44:55'));
      expect(accessPoint.signalLevel, equals(-45));
      expect(accessPoint.security, equals('WPA2'));
      expect(accessPoint.frequency, equals(2437));
    });

    test('AndroidWiFiAccessPoint toString works', () {
      final accessPoint = AndroidWiFiAccessPoint(
        ssid: 'TestNetwork',
        bssid: '00:11:22:33:44:55',
        signalLevel: -45,
        security: 'WPA2',
        frequency: 2437,
      );

      final string = accessPoint.toString();
      expect(string, contains('TestNetwork'));
      expect(string, contains('00:11:22:33:44:55'));
      expect(string, contains('-45 dBm'));
      expect(string, contains('WPA2'));
      expect(string, contains('2437 MHz'));
    });

    test('AndroidDataStreamingService initial state', () {
      final streamingService = AndroidDataStreamingService();
      expect(streamingService.isStreaming, isFalse);
    });
  });
}
