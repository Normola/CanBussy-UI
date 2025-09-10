# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0+1] - 2025-09-10

### Added
- Initial release of CanBussy UI
- WiFi connection management for Android devices
- Network scanning and device discovery
- Data streaming from connected devices
- Enhanced connectivity status detection (WiFi with/without internet)
- Android WiFi troubleshooting dialog and guidance
- Automatic endpoint URL detection from gateway
- Connection status monitoring with detailed feedback
- GitHub Actions CI/CD pipeline with automated versioning
- Dependabot integration for automated dependency updates
- Comprehensive documentation and troubleshooting guides

### Features
- **WiFi Management**: Scan, connect, and monitor WiFi networks
- **Smart Connectivity**: Distinguish between WiFi+Internet vs WiFi-only connections
- **Data Streaming**: Real-time data streaming from CanBussy devices
- **Troubleshooting**: Step-by-step guidance for connection issues
- **Cross-platform**: Designed for Android with Windows support framework
- **Automated CI/CD**: GitHub Actions for building and deployment
- **Dependency Management**: Automated updates via Dependabot

### Technical Details
- Built with Flutter 3.27.0
- Uses connectivity_plus for network detection
- Implements enhanced WiFi priority detection
- Features robust error handling and user feedback
- Includes comprehensive logging for debugging
