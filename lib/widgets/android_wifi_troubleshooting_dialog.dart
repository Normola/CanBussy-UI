import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AndroidWiFiTroubleshootingDialog extends StatelessWidget {
  final String ssid;
  final Map<String, dynamic> troubleshooting;

  const AndroidWiFiTroubleshootingDialog({
    super.key,
    required this.ssid,
    required this.troubleshooting,
  });

  @override
  Widget build(BuildContext context) {
    final ipConfigSteps = troubleshooting['ipConfigFailure']['steps'] as List;
    final staticIpSteps =
        troubleshooting['ipConfigFailure']['staticIpSteps'] as List;
    final commonCauses = troubleshooting['commonCauses'] as List;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'WiFi Connection Help',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connecting to: $ssid',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'If you see "IP Configuration Failure", follow these steps:',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Quick fixes
            _buildSection(
              context,
              'Quick Fixes',
              Icons.flash_on,
              ipConfigSteps.take(4).toList(),
              Colors.blue,
            ),

            SizedBox(height: 16),

            // Static IP configuration
            _buildSection(
              context,
              'Use Static IP (Advanced)',
              Icons.settings_ethernet,
              staticIpSteps,
              Colors.green,
            ),

            SizedBox(height: 16),

            // Common causes
            _buildSection(
              context,
              'Common Causes',
              Icons.info_outline,
              commonCauses,
              Colors.orange,
            ),

            SizedBox(height: 16),

            // Network information
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.network_check,
                          size: 16, color: Colors.grey.shade600),
                      SizedBox(width: 8),
                      Text(
                        'Typical Network Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'IP: 192.168.1.100\n'
                    'Gateway: 192.168.1.1\n'
                    'DNS: 8.8.8.8\n'
                    'Subnet: 255.255.255.0',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(
                          text:
                              'IP: 192.168.1.100\nGateway: 192.168.1.1\nDNS: 8.8.8.8\nSubnet: 255.255.255.0'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Network settings copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Copy to clipboard',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // You could add a callback here to retry connection
          },
          child: Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<dynamic> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: items.map<Widget>((item) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show the troubleshooting dialog
void showAndroidWiFiTroubleshooting(
  BuildContext context,
  String ssid,
  Map<String, dynamic> troubleshooting,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AndroidWiFiTroubleshootingDialog(
      ssid: ssid,
      troubleshooting: troubleshooting,
    ),
  );
}
