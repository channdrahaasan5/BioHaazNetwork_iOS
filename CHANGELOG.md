# Changelog

All notable changes to the BioHaazNetwork iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-15

### Added
- Initial release of BioHaazNetwork iOS SDK
- Core networking functionality with GET, POST, PUT, DELETE methods
- Offline queue system with automatic request queuing
- Background processing for queued requests when app is backgrounded/killed
- Enhanced debug logging with timestamps and request IDs
- Notification system for offline request processing status
- Network state monitoring and automatic queue processing
- Configurable retry policies and timeouts
- SSL certificate pinning support
- Request/response interceptors
- Comprehensive error handling
- Performance tracking and monitoring
- Complete documentation and usage examples

### Features
- **HTTP Methods**: Full support for GET, POST, PUT, DELETE with custom headers
- **Offline Queue**: Automatic queuing of requests when network is unavailable
- **Background Processing**: Process queued requests in background/killed states
- **Enhanced Logging**: Detailed API request/response logging with file output
- **Notification Support**: User notifications for offline request processing
- **Network Monitoring**: Automatic network state detection and queue processing
- **Retry Policy**: Configurable retry mechanisms with exponential backoff
- **SSL Pinning**: Enhanced security with certificate pinning
- **Performance Tracking**: Built-in performance monitoring and metrics
- **Error Handling**: Comprehensive error types and handling strategies

### Technical Details
- **Minimum iOS Version**: 13.0+
- **Swift Version**: 5.0+
- **Xcode Version**: 12.0+
- **Architecture Support**: arm64 (device), x86_64 (simulator)
- **Framework Size**: ~2.5MB
- **Dependencies**: None (self-contained)

### Documentation
- Complete README with quick start guide
- Detailed USAGE.md with comprehensive examples
- Installation guide with troubleshooting
- Sample project demonstrating integration
- API reference documentation

### Breaking Changes
- None (initial release)

### Migration Guide
- N/A (initial release)

## [1.0.5] - 2025-01-XX

### Fixed
- **Offline Queue Enhancement**: Fixed offline queue to support DELETE, PUT, and PATCH methods in addition to POST
  - Previously, only POST requests were queued when offline
  - DELETE and UPDATE operations now properly queue when network is unavailable
  - All queued requests (POST, PUT, PATCH, DELETE) are automatically processed when network is restored
  - Improved debug logging to show the correct HTTP method in queue messages

### Changed
- Updated offline queue logic to handle all mutating HTTP methods
- Enhanced documentation to reflect offline queue support for all mutating operations

## [1.0.4] - 2025-01-XX

### Removed
- CocoaPods support removed from the SDK

### Changed
- Focus on Swift Package Manager and Framework distribution
- Updated all documentation to reflect new installation methods

## [1.0.3] - 2025-01-XX

### Fixed
- Swift Package Manager compatibility issues
- Fixed Git tag naming (lowercase 'v' prefix for semantic versioning)

## [1.0.2] - 2025-01-XX

### Fixed
- Fixed `BioHaazKeychain` not being included in Swift Package Manager builds
- Updated `.gitignore` to explicitly include `BioHaazKeychain.swift`

## [1.0.1] - 2025-01-XX

### Added
- Swift Package Manager support

## [Unreleased]

### Planned Features
- Swift Package Manager support
- CocoaPods integration
- Carthage support
- Unit tests and test coverage
- CI/CD pipeline
- Performance benchmarks
- Additional logging formats (JSON, XML)
- Request caching mechanisms
- Advanced retry strategies
- WebSocket support
- GraphQL integration
- Request/response compression
- Advanced analytics and metrics




