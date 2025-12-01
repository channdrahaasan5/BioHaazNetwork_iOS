# BioHaazNetwork iOS SDK

A powerful and feature-rich networking SDK for iOS applications with offline support, comprehensive logging, and extensible architecture.

## Features

- ✅ **HTTP Methods**: GET, POST, PUT, DELETE with full customization
- ✅ **Multi-Environment Support**: Easy switching between dev, qa, uat, prod environments
- ✅ **Offline Queue**: Automatic request queuing when network is unavailable
- ✅ **Manual Queue Processing**: Process queued requests on-demand
- ✅ **Enhanced Logging**: Comprehensive API request/response logging with timestamps
- ✅ **Network Monitoring**: Automatic network state detection
- ✅ **Retry Policy**: Configurable retry mechanisms
- ✅ **Performance Tracking**: Built-in performance monitoring
- ✅ **File Upload/Download**: Complete file transfer capabilities with progress tracking
- ✅ **Image Loading**: UIImageView extension for easy image loading
- ✅ **Plugin System**: Extensible architecture with custom plugins
- ✅ **Interceptors**: Request/response modification capabilities
- ✅ **Token Management**: Automatic token refresh and secure storage
- ✅ **Objective-C Support**: Full compatibility with Objective-C projects

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

### Swift Package Manager (Recommended)

**Via Xcode:**
1. In Xcode, go to **File → Add Packages...**
2. Enter: `https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git`
3. Select version: `1.0.4` or later
4. Click **Add Package**

**Via Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git", from: "1.0.4")
]
```

### Manual Installation (.framework)

1. Download `BioHaazNetwork-v1.0.4.framework.zip` from the [Releases](https://github.com/channdrahaasan5/BioHaazNetwork_iOS/releases) page
2. Extract the zip file
3. Drag and drop `BioHaazNetwork.framework` into your Xcode project
4. Make sure "Copy items if needed" is checked
5. Add the framework to your target's "Embedded Binaries" in Build Phases

## Quick Start

### Swift

```swift
import BioHaazNetwork

// Initialize SDK
let config = BioHaazNetworkConfig(
    environments: [
        .dev: "https://dev.api.example.com",
        .qa: "https://qa.api.example.com",
        .prod: "https://api.example.com"
    ],
    defaultEnvironment: .dev,
    loggingEnabled: true
)

BioHaazNetworkManager.shared.initialize(config: config)

// Make a request
BioHaazNetworkManager.shared.request(
    endpoint: "/users",
    method: .get
) { result in
    switch result {
    case .success(let response):
        print("Success: \(response)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Objective-C

```objc
#import <BioHaazNetwork/BioHaazNetwork-Swift.h>

// Initialize SDK
BioHaazNetworkConfig *config = [[BioHaazNetworkConfig alloc] 
    initWithEnvironments:@{
        @(BioHaazEnvironmentDev): @"https://dev.api.example.com",
        @(BioHaazEnvironmentProd): @"https://api.example.com"
    }
    defaultEnvironment:BioHaazEnvironmentDev
    loggingEnabled:YES];

[[BioHaazNetworkManager shared] initializeWithConfig:config];

// Make a request
[[BioHaazNetworkManager shared] requestWithEndpoint:@"/users"
    method:BioHaazHTTPMethodGet
    completion:^(BioHaazNetworkResponse * _Nullable response, NSError * _Nullable error) {
    if (response) {
        NSLog(@"Success: %@", response);
    } else {
        NSLog(@"Error: %@", error);
    }
}];
```

## Documentation

- [Installation Guide](INSTALLATION.md)
- [API Reference](API_REFERENCE.md)
- [Usage Guide](USAGE.md)
- [SDK Initialization](Documentation/SDKInitialization.md)
- [SDK Topics](Documentation/SDKTopics.md)
- [Use Cases](Documentation/SDKUseCases.md)

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions, please visit:
https://github.com/channdrahaasan5/BioHaazNetwork_iOS

## Version

Current version: **1.0.4**

See [CHANGELOG.md](CHANGELOG.md) for version history.
