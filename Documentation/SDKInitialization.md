# BioHaazNetwork SDK - Initialization Guide

Complete guide to initializing and configuring the BioHaazNetwork SDK for iOS applications.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Configuration Parameters](#configuration-parameters)
4. [Complete Examples](#complete-examples)
5. [Best Practices](#best-practices)

---

## Overview

The BioHaazNetwork SDK is initialized using a `BioHaazNetworkConfig` object that contains all configuration settings. Once initialized, the SDK is ready to make network requests.

### Key Points

- **Single Initialization**: Initialize once, typically in `AppDelegate` or `SceneDelegate`
- **Shared Instance**: Use `BioHaazNetworkManager.shared` to access the SDK
- **Thread-Safe**: The SDK is thread-safe and can be used from any thread
- **Persistent Configuration**: Configuration persists until app restart or re-initialization

---

## Quick Start

### Swift

```swift
import BioHaazNetwork

// 1. Create configuration
let config = BioHaazNetworkConfig(
    environments: [
        .dev: "https://dev-api.example.com",
        .prod: "https://api.example.com"
    ],
    defaultEnvironment: .prod,
    loggingEnabled: true,
    timeout: 30,
    autoOfflineProcess: true,
    debug: false
)

// 2. Initialize SDK
BioHaazNetworkManager.shared.initialize(with: config)

// 3. Start making requests
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users",
    completion: { result in
        // Handle response
    }
)
```

### Objective-C

```objc
#import <BioHaazNetwork/BioHaazNetwork-Swift.h>

// 1. Create configuration
NSDictionary *environments = @{
    @(BioHaazEnvironmentDev): @"https://dev-api.example.com",
    @(BioHaazEnvironmentProd): @"https://api.example.com"
};

BioHaazNetworkConfig *config = [[BioHaazNetworkConfig alloc] 
    initWithEnvironments:environments
    defaultEnvironment:BioHaazEnvironmentProd
    loggingEnabled:YES
    timeout:30
    plugins:@[]
    interceptors:@[]
    autoOfflineProcess:YES
    debug:NO];

// 2. Initialize SDK
[[BioHaazNetworkManager shared] initializeWithConfig:config];

// 3. Start making requests
[[BioHaazNetworkManager shared] requestWithMethod:@"GET"
                                               url:@"/users"
                                          headers:nil
                                           params:nil
                                        completion:^(id result, BioHaazNetworkError *error) {
    // Handle response
}];
```

---

## Configuration Parameters

### 1. `environments`

**Type:** `[BioHaazEnvironment: String]`  
**Required:** Yes  
**Default:** None

**Description:**  
Maps environment identifiers to their base URLs. Allows you to easily switch between different backend environments (development, QA, production, etc.).

**Environments Available:**
- `.dev` - Development environment
- `.qa` - Quality Assurance environment
- `.uat` - User Acceptance Testing environment
- `.prod` - Production environment

**Swift Example:**
```swift
let environments: [BioHaazEnvironment: String] = [
    .dev: "https://dev-api.example.com",
    .qa: "https://qa-api.example.com",
    .uat: "https://uat-api.example.com",
    .prod: "https://api.example.com"
]
```

**Objective-C Example:**
```objc
NSDictionary *environments = @{
    @(BioHaazEnvironmentDev): @"https://dev-api.example.com",
    @(BioHaazEnvironmentQA): @"https://qa-api.example.com",
    @(BioHaazEnvironmentUAT): @"https://uat-api.example.com",
    @(BioHaazEnvironmentProd): @"https://api.example.com"
};
```

**Best Practices:**
- Always include at least `.dev` and `.prod` environments
- Use HTTPS URLs for production
- Store URLs in configuration files or environment variables

---

### 2. `defaultEnvironment`

**Type:** `BioHaazEnvironment`  
**Required:** No  
**Default:** `.prod`

**Description:**  
Sets the initial environment that will be used for all network requests. You can change this at runtime using `setEnvironment(_:)`.

**Swift Example:**
```swift
defaultEnvironment: .dev  // Use development environment by default
```

**Objective-C Example:**
```objc
defaultEnvironment:BioHaazEnvironmentDev
```

**Changing Environment at Runtime:**
```swift
// Switch to production
BioHaazNetworkManager.shared.setEnvironment(.prod)

// Get current environment
let currentEnv = BioHaazNetworkManager.shared.getCurrentEnvironment()

// Get current base URL
let baseURL = BioHaazNetworkManager.shared.getBaseURL()
```

---

### 3. `loggingEnabled`

**Type:** `Bool`  
**Required:** No  
**Default:** `false`

**Description:**  
Enables automatic logging of network requests and responses. When enabled, the SDK logs:
- Request method, URL, headers, and body
- Response status code, headers, and body
- Request duration
- Errors

**Swift Example:**
```swift
loggingEnabled: true  // Enable logging
```

**Objective-C Example:**
```objc
loggingEnabled:YES
```

**Accessing Logs:**
```swift
// Get log file URL
let logFileURL = BioHaazLogger.shared.getLogFileURL()

// Custom logging
BioHaazLogger.shared.log("Custom message", level: "INFO")
```

**Log Levels:**
- `INFO` - General information
- `DEBUG` - Debug information
- `SUCCESS` - Successful operations
- `WARNING` - Warnings
- `ERROR` - Errors

---

### 4. `timeout`

**Type:** `TimeInterval` (Double, in seconds)  
**Required:** No  
**Default:** `30.0`

**Description:**  
Sets the timeout duration for all network requests. If a request takes longer than this duration, it will be cancelled and return a timeout error.

**Swift Example:**
```swift
timeout: 60.0  // 60 seconds timeout
```

**Objective-C Example:**
```objc
timeout:60.0
```

**Best Practices:**
- Use 30-60 seconds for most APIs
- Use longer timeouts (90-120 seconds) for file uploads
- Use shorter timeouts (10-15 seconds) for quick API calls

---

### 5. `plugins`

**Type:** `[BioHaazPlugin]`  
**Required:** No  
**Default:** `[]` (empty array)

**Description:**  
Array of plugin objects that observe network requests and responses. Plugins are called before requests are sent and after responses are received. They cannot modify requests/responses.

**Use Cases:**
- Analytics tracking
- External logging services
- Monitoring API calls
- Custom event handling

**Swift Example:**
```swift
// Create a plugin
class AnalyticsPlugin: BioHaazPlugin {
    func onRequest(_ request: URLRequest) {
        // Track request started
        Analytics.track("api_request", parameters: [
            "url": request.url?.absoluteString ?? "",
            "method": request.httpMethod ?? ""
        ])
    }
    
    func onResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        // Track response
        if let httpResponse = response as? HTTPURLResponse {
            Analytics.track("api_response", parameters: [
                "status_code": httpResponse.statusCode,
                "success": error == nil
            ])
        }
    }
}

// Add to config
let config = BioHaazNetworkConfig(
    // ... other params ...
    plugins: [AnalyticsPlugin()]
)
```

**Registering Plugins Dynamically:**
```swift
// Add plugin after initialization
let newPlugin = MyCustomPlugin()
BioHaazNetworkManager.shared.registerPlugin(newPlugin)
```

**Objective-C:**  
Plugins must be implemented in Swift, but can be registered from Objective-C if exposed.

---

### 6. `interceptors`

**Type:** `[BioHaazInterceptor]`  
**Required:** No  
**Default:** `[]` (empty array)

**Description:**  
Array of interceptor objects that can modify requests and process responses. Interceptors are executed in order and can transform requests before they're sent.

**Use Cases:**
- Adding authentication headers
- Encrypting/decrypting data
- Adding custom headers
- Response transformation

**Swift Example:**
```swift
// Create an interceptor
class AuthInterceptor: BioHaazInterceptor {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func intercept(_ request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        // Add API key to every request
        modifiedRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return modifiedRequest
    }
    
    func intercept(_ response: URLResponse?, data: Data?, error: Error?) {
        // Handle 401 errors
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            // Trigger token refresh
            print("Unauthorized - need to refresh token")
        }
    }
}

// Add to config
let config = BioHaazNetworkConfig(
    // ... other params ...
    interceptors: [AuthInterceptor(apiKey: "your-api-key")]
)
```

**Multiple Interceptors:**
```swift
// Interceptors execute in order
let authInterceptor = AuthInterceptor(apiKey: "key123")
let headerInterceptor = HeaderInterceptor()

let config = BioHaazNetworkConfig(
    // ... other params ...
    interceptors: [authInterceptor, headerInterceptor]  // Executed in this order
)
```

**Objective-C:**  
Interceptors must be implemented in Swift, but can be registered from Objective-C if exposed.

---

### 7. `performanceTracker`

**Type:** `BioHaazPerformanceTracker?`  
**Required:** No  
**Default:** `nil`

**Description:**  
Optional performance tracker that monitors API performance metrics. Tracks duration, success rate, and network speed for each request.

**Use Cases:**
- Performance monitoring
- Identifying slow APIs
- Analytics dashboards
- Network speed tracking

**Swift Example:**
```swift
// Using default implementation
let performanceTracker = BioHaazDefaultPerformanceTracker { report in
    print("API Performance:")
    print("  URL: \(report.url)")
    print("  Method: \(report.method)")
    print("  Duration: \(report.duration)s")
    print("  Success: \(report.success)")
    if let speed = report.speed {
        print("  Speed: \(speed) bytes/sec")
    }
}

let config = BioHaazNetworkConfig(
    // ... other params ...
    performanceTracker: performanceTracker
)
```

**Custom Performance Tracker:**
```swift
class CustomPerformanceTracker: BioHaazPerformanceTracker {
    func track(request: URLRequest, duration: TimeInterval, success: Bool, speed: Double?) {
        // Send to analytics
        Analytics.trackPerformance(
            endpoint: request.url?.path ?? "",
            duration: duration,
            success: success,
            speed: speed
        )
        
        // Alert if slow
        if duration > 5.0 {
            print("⚠️ Slow API: \(request.url?.absoluteString ?? "") took \(duration)s")
        }
    }
}

let config = BioHaazNetworkConfig(
    // ... other params ...
    performanceTracker: CustomPerformanceTracker()
)
```

**Objective-C:**  
Performance trackers must be implemented in Swift, but can be registered from Objective-C if exposed.

---

### 8. `autoOfflineProcess`

**Type:** `Bool`  
**Required:** No  
**Default:** `true`

**Description:**  
Enables automatic queuing of POST, PUT, PATCH, and DELETE requests when the device is offline. Queued requests are automatically processed when:
- The app becomes active
- Network connectivity is restored

**Swift Example:**
```swift
autoOfflineProcess: true  // Enable automatic offline queue processing
```

**Objective-C Example:**
```objc
autoOfflineProcess:YES
```

**How It Works:**
1. When offline, POST, PUT, PATCH, and DELETE requests are automatically queued
2. Queue is processed when app becomes active (if enabled)
3. Queue is processed when network is restored (if enabled)
4. You can also manually process the queue using `processOfflineQueue()`

**Manual Processing:**
```swift
// Process queue manually (recommended when app wakes up from background)
BioHaazNetworkManager.shared.processOfflineQueue { result in
    switch result {
    case .success(let processingResult):
        print("Processed: \(processingResult.processedCount)")
        print("Failed: \(processingResult.failedCount)")
        print("Remaining: \(processingResult.remainingCount)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}
```

**Queue Status:**
```swift
// Check queue status
let (count, hasItems) = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
if hasItems {
    print("Queue has \(count) items")
}

// Get detailed status
let status = BioHaazNetworkManager.shared.getOfflineQueueStatus()
let queueCount = status["offlineRequestsCount"] as? Int ?? 0
```

---

### 9. `debug`

**Type:** `Bool`  
**Required:** No  
**Default:** `false`

**Description:**  
Enables verbose debug logging for development. When enabled, provides detailed logs including:
- Request/response details
- Queue processing status
- Network state changes
- Error details

**Swift Example:**
```swift
debug: true  // Enable debug mode (only for development)
```

**Objective-C Example:**
```objc
debug:YES
```

**Best Practices:**
- Enable `debug: true` only in development builds
- Disable in production for better performance
- Use conditional compilation:

```swift
#if DEBUG
    debug: true
#else
    debug: false
#endif
```

---

## Complete Examples

### Example 1: Basic Configuration

**Swift:**
```swift
import BioHaazNetwork

func setupSDK() {
    let config = BioHaazNetworkConfig(
        environments: [
            .dev: "https://dev-api.example.com",
            .prod: "https://api.example.com"
        ],
        defaultEnvironment: .prod,
        loggingEnabled: true,
        timeout: 30,
        autoOfflineProcess: true,
        debug: false
    )
    
    BioHaazNetworkManager.shared.initialize(with: config)
}
```

**Objective-C:**
```objc
#import <BioHaazNetwork/BioHaazNetwork-Swift.h>

- (void)setupSDK {
    NSDictionary *environments = @{
        @(BioHaazEnvironmentDev): @"https://dev-api.example.com",
        @(BioHaazEnvironmentProd): @"https://api.example.com"
    };
    
    BioHaazNetworkConfig *config = [[BioHaazNetworkConfig alloc] 
        initWithEnvironments:environments
        defaultEnvironment:BioHaazEnvironmentProd
        loggingEnabled:YES
        timeout:30
        plugins:@[]
        interceptors:@[]
        autoOfflineProcess:YES
        debug:NO];
    
    [[BioHaazNetworkManager shared] initializeWithConfig:config];
}
```

---

### Example 2: With Plugins and Interceptors

**Swift:**
```swift
import BioHaazNetwork

func setupSDK() {
    // Create plugins
    let analyticsPlugin = AnalyticsPlugin()
    let loggingPlugin = ExternalLoggingPlugin()
    
    // Create interceptors
    let authInterceptor = AuthInterceptor(apiKey: "your-api-key")
    let headerInterceptor = HeaderInterceptor()
    
    // Create performance tracker
    let performanceTracker = BioHaazDefaultPerformanceTracker { report in
        // Track performance metrics
        Analytics.trackPerformance(report)
    }
    
    let config = BioHaazNetworkConfig(
        environments: [
            .dev: "https://dev-api.example.com",
            .prod: "https://api.example.com"
        ],
        defaultEnvironment: .prod,
        loggingEnabled: true,
        timeout: 60,
        plugins: [analyticsPlugin, loggingPlugin],
        interceptors: [authInterceptor, headerInterceptor],
        performanceTracker: performanceTracker,
        autoOfflineProcess: true,
        debug: false
    )
    
    BioHaazNetworkManager.shared.initialize(with: config)
}
```

---

### Example 3: AppDelegate Integration

**Swift:**
```swift
import UIKit
import BioHaazNetwork

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize SDK
        setupBioHaazNetwork()
        
        return true
    }
    
    private func setupBioHaazNetwork() {
        let config = BioHaazNetworkConfig(
            environments: [
                .dev: "https://dev-api.example.com",
                .prod: "https://api.example.com"
            ],
            defaultEnvironment: .prod,
            loggingEnabled: true,
            timeout: 30,
            autoOfflineProcess: true,
            debug: false
        )
        
        BioHaazNetworkManager.shared.initialize(with: config)
        
        print("✅ BioHaazNetwork SDK initialized")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Process offline queue when app becomes active
        let queueStatus = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
        if queueStatus.hasItems {
            BioHaazNetworkManager.shared.processOfflineQueue { result in
                switch result {
                case .success(let processingResult):
                    print("✅ Processed \(processingResult.processedCount) queued requests")
                case .failure(let error):
                    print("❌ Failed to process queue: \(error.localizedDescription)")
                }
            }
        }
    }
}
```

---

### Example 4: Environment-Specific Configuration

**Swift:**
```swift
func setupSDK() {
    #if DEBUG
        let defaultEnv: BioHaazEnvironment = .dev
        let debugMode = true
    #else
        let defaultEnv: BioHaazEnvironment = .prod
        let debugMode = false
    #endif
    
    let config = BioHaazNetworkConfig(
        environments: [
            .dev: "https://dev-api.example.com",
            .qa: "https://qa-api.example.com",
            .prod: "https://api.example.com"
        ],
        defaultEnvironment: defaultEnv,
        loggingEnabled: true,
        timeout: 30,
        autoOfflineProcess: true,
        debug: debugMode
    )
    
    BioHaazNetworkManager.shared.initialize(with: config)
}
```

---

## Best Practices

### 1. Initialize Early

Initialize the SDK as early as possible in your app lifecycle, typically in:
- `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- `SceneDelegate.scene(_:willConnectTo:options:)`

### 2. Use Environment Variables

Store API URLs in environment variables or configuration files:

```swift
let config = BioHaazNetworkConfig(
    environments: [
        .dev: ProcessInfo.processInfo.environment["DEV_API_URL"] ?? "https://dev-api.example.com",
        .prod: ProcessInfo.processInfo.environment["PROD_API_URL"] ?? "https://api.example.com"
    ],
    // ... other params
)
```

### 3. Conditional Debug Mode

Only enable debug mode in development:

```swift
#if DEBUG
    debug: true
#else
    debug: false
#endif
```

### 4. Process Queue on App Activation

Always process the offline queue when the app becomes active:

```swift
func applicationDidBecomeActive(_ application: UIApplication) {
    BioHaazNetworkManager.shared.processOfflineQueue { _ in }
}
```

### 5. Handle Queue Status

Check queue status before processing:

```swift
let (count, hasItems) = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
if hasItems {
    // Process queue
}
```

### 6. Use Appropriate Timeouts

- **Quick APIs**: 15-30 seconds
- **Standard APIs**: 30-60 seconds
- **File Uploads**: 90-120 seconds

### 7. Register Plugins for Analytics

Use plugins for analytics instead of modifying SDK code:

```swift
let analyticsPlugin = AnalyticsPlugin()
let config = BioHaazNetworkConfig(
    // ... other params ...
    plugins: [analyticsPlugin]
)
```

---

## Summary

| Parameter | Type | Required | Default | Purpose |
|-----------|------|----------|---------|---------|
| `environments` | `[BioHaazEnvironment: String]` | Yes | - | Maps environments to base URLs |
| `defaultEnvironment` | `BioHaazEnvironment` | No | `.prod` | Initial environment |
| `loggingEnabled` | `Bool` | No | `false` | Enable request/response logging |
| `timeout` | `TimeInterval` | No | `30.0` | Request timeout in seconds |
| `plugins` | `[BioHaazPlugin]` | No | `[]` | Observers for requests/responses |
| `interceptors` | `[BioHaazInterceptor]` | No | `[]` | Request/response modifiers |
| `performanceTracker` | `BioHaazPerformanceTracker?` | No | `nil` | Performance monitoring |
| `autoOfflineProcess` | `Bool` | No | `true` | Auto-process offline queue |
| `debug` | `Bool` | No | `false` | Verbose debug logging |

---

## Next Steps

After initialization, you can:
- Make network requests using `request(method:url:completion:)`
- Upload files using `uploadFile(url:fileData:completion:)`
- Download files using `downloadFile(from:to:completion:)`
- Process offline queue using `processOfflineQueue(completion:)`
- Check queue status using `checkOfflineQueueStatus()`

For more information, see:
- `SDKTopics.md` - Detailed topic explanations
- `SDKUseCases.md` - Practical use cases and examples
- `PLUGINS_INTERCEPTORS_PERFORMANCE_GUIDE.md` - Advanced features guide
