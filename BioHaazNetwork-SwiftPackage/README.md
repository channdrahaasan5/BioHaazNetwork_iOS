# BioHaazNetwork

A powerful and feature-rich networking SDK for iOS applications with offline support, background processing, and comprehensive logging.

## Features

- ✅ **HTTP Methods**: GET, POST, PUT, DELETE with full customization
- ✅ **Multi-Environment Support**: Easy switching between dev, qa, uat, prod environments
- ✅ **Offline Queue**: Automatic request queuing when network is unavailable
- ✅ **Background Processing**: Process queued requests when app is in background
- ✅ **Enhanced Logging**: Comprehensive API request/response logging with timestamps
- ✅ **Notification Support**: User notifications for offline request processing
- ✅ **Network Monitoring**: Automatic network state detection
- ✅ **Retry Policy**: Configurable retry mechanisms
- ✅ **SSL Pinning**: Enhanced security with certificate pinning
- ✅ **Performance Tracking**: Built-in performance monitoring
- ✅ **File Upload/Download**: Complete file transfer capabilities with progress tracking
- ✅ **Image Loading**: UIImageView extension for easy image loading
- ✅ **Mock Mode**: Testing support with mock responses
- ✅ **Plugin System**: Extensible architecture with custom plugins
- ✅ **Interceptors**: Request/response modification capabilities
- ✅ **Token Management**: Automatic token refresh and secure storage
- ✅ **Objective-C Support**: Full compatibility with Objective-C projects

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git`
3. Select the version and add to your target

## Quick Start

### Swift

```swift
import BioHaazNetwork

// Initialize the SDK
let config = BioHaazNetworkConfig(
    environments: [
        .dev: "https://dev.api.example.com",
        .prod: "https://api.example.com"
    ],
    defaultEnvironment: .prod,
    debug: true,
    autoOfflineProcess: true,
    offlineNotificationService: true
)

BioHaazNetworkManager.shared.initialize(with: config)

// Make API calls
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users"
) { result in
    switch result {
    case .success(let data):
        print("Success: \(data)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Objective-C

```objc
#import <BioHaazNetwork/BioHaazNetwork-Swift.h>

// Initialize the SDK
NSDictionary *environments = @{
    @(BioHaazEnvironmentDev): @"https://dev.api.example.com",
    @(BioHaazEnvironmentProd): @"https://api.example.com"
};

BioHaazNetworkConfig *config = [[BioHaazNetworkConfig alloc] 
    initWithEnvironments:environments
    defaultEnvironment:BioHaazEnvironmentProd
    debug:YES
    autoOfflineProcess:YES
    offlineNotificationService:YES];

[[BioHaazNetworkManager shared] initializeWithConfig:config];

// Make API calls
[[BioHaazNetworkManager shared] requestWithMethod:@"GET"
    url:@"/users"
    completion:^(Result<Data, BioHaazNetworkError> *result) {
    if (result.isSuccess) {
        NSLog(@"Success: %@", result.data);
    } else {
        NSLog(@"Error: %@", result.error.localizedDescription);
    }
}];
```

## Documentation

For detailed usage examples and API reference, see:
- [Complete Usage Guide](USAGE.md)
- [API Reference](API_REFERENCE.md)
- [Installation Guide](INSTALLATION.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For support, issues, and feature requests:
- GitHub Issues: [Repository URL]
- Documentation: [Documentation URL]
- Email: [Support Email]




