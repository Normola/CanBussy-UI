import 'package:flutter/foundation.dart';

/// Version information helper class
/// This class provides access to version information set during build time
class VersionInfo {
  // Version information that can be set during build via --dart-define
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1-dev',
  );

  static const String buildName = String.fromEnvironment(
    'BUILD_NAME',
    defaultValue: '1.0.0',
  );

  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '1',
  );

  static const String gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'unknown',
  );

  static const String buildDate = String.fromEnvironment(
    'BUILD_DATE',
    defaultValue: 'unknown',
  );

  /// Get the full version string including build metadata
  static String get fullVersion => appVersion;

  /// Get just the version number (without build metadata)
  static String get version => buildName;

  /// Get the build number
  static String get build => buildNumber;

  /// Get short commit hash
  static String get commit =>
      gitCommit.length > 7 ? gitCommit.substring(0, 7) : gitCommit;

  /// Get build date
  static String get date => buildDate;

  /// Get formatted version info for display
  static String get displayVersion {
    if (kDebugMode) {
      return '$buildName ($buildNumber) - Debug';
    } else {
      return '$buildName ($buildNumber)';
    }
  }

  /// Get detailed version info for about screen
  static String get detailedVersion {
    final buffer = StringBuffer();
    buffer.writeln('Version: $buildName');
    buffer.writeln('Build: $buildNumber');

    if (commit != 'unknown') {
      buffer.writeln('Commit: $commit');
    }

    if (date != 'unknown') {
      buffer.writeln('Built: $date');
    }

    if (kDebugMode) {
      buffer.writeln('Mode: Debug');
    } else {
      buffer.writeln('Mode: Release');
    }

    return buffer.toString().trim();
  }

  /// Check if this is a development build
  static bool get isDevelopmentBuild {
    return appVersion.contains('-dev') ||
        appVersion.contains('-branch') ||
        kDebugMode;
  }

  /// Check if this is a release build
  static bool get isReleaseBuild {
    return !isDevelopmentBuild && !kDebugMode;
  }

  /// Get a map of all version information
  static Map<String, String> get versionMap {
    return {
      'appVersion': appVersion,
      'buildName': buildName,
      'buildNumber': buildNumber,
      'gitCommit': gitCommit,
      'buildDate': buildDate,
      'mode': kDebugMode ? 'debug' : 'release',
    };
  }
}
