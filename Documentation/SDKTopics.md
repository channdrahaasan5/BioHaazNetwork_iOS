# BioHaazNetwork SDK: Topic-wise Detailed Explanation

This document provides a detailed, topic-by-topic explanation of the BioHaazNetwork SDK, including configuration, usage, and code samples.

---

## 1. Initialization

**Purpose:** Set up the SDK with all required configuration before making network requests.

**How it works:**
- Create a `BioHaazNetworkConfig` object with all necessary parameters.
- Call `BioHaazNetworkManager.shared.initialize(with: config)`.

**Swift:**
```swift
let config = BioHaazNetworkConfig(
    environments: [
        .dev: "https://dev.api.example.com",
        .prod: "https://api.example.com"
    ],
    defaultEnvironment: .prod,
    loggingEnabled: true,
    timeout: 60,
    plugins: [],
    interceptors: [],
    performanceTracker: nil,
    autoOfflineProcess: true,
    debug: true
)
BioHaazNetworkManager.shared.initialize(with: config)
```

**Objective-C:**
```objc
#import <BioHaazNetwork/BioHaazNetwork-Swift.h>
NSDictionary *envs = @{
    @(BioHaazEnvironmentDev): @"https://dev.api.example.com",
    @(BioHaazEnvironmentProd): @"https://api.example.com"
};
BioHaazNetworkConfig *config = [[BioHaazNetworkConfig alloc] initWithEnvironments:envs
                                                              defaultEnvironment:BioHaazEnvironmentProd
                                                              loggingEnabled:YES
                                                              timeout:60
                                                              plugins:@[]
                                                              interceptors:@[]
                                                              performanceTracker:nil
                                                              autoOfflineProcess:YES
                                                              debug:YES];
[[BioHaazNetworkManager shared] initializeWithConfig:config];
```

---

## 2. Environments

**Purpose:** Support multiple backend environments (dev, qa, uat, prod) and switch between them easily.

**How it works:**
- Use the `environments` dictionary in config to map environments to base URLs.
- Use `setEnvironment(_:)` to switch environments at runtime.

**Swift:**
```swift
BioHaazNetworkManager.shared.setEnvironment(.dev)
let currentEnv = BioHaazNetworkManager.shared.getCurrentEnvironment()
let baseURL = BioHaazNetworkManager.shared.getBaseURL()
```

**Objective-C:**
```objc
[[BioHaazNetworkManager shared] setEnvironment:BioHaazEnvironmentDev];
BioHaazEnvironment env = [[BioHaazNetworkManager shared] getCurrentEnvironment];
NSString *baseURL = [[BioHaazNetworkManager shared] getBaseURL];
```

---

## 3. Logging

**Purpose:** Debug and monitor network requests and responses.

**How it works:**
- Enable `loggingEnabled` in config for automatic logging.
- Use `BioHaazLogger` for custom logs.

**Swift:**
```swift
BioHaazLogger.shared.log("Custom log message", level: "DEBUG")
let logFileURL = BioHaazLogger.shared.getLogFileURL()
```

**Objective-C:**
```objc
[BioHaazLogger.shared log:@"Custom log message" level:@"DEBUG"];
NSURL *logFileURL = [BioHaazLogger.shared getLogFileURL];
```

---

## 4. Plugins

**Purpose:** Extend SDK functionality with analytics, hooks, or custom error handling.

**How it works:**
- Implement the `BioHaazPlugin` protocol in Swift.
- Register plugins via config or `registerPlugin(_:)`.

**Swift:**
```swift
class MyPlugin: BioHaazPlugin {
    func onRequest(_ request: URLRequest) { print("Request: \(request)") }
    func onResponse(_ response: URLResponse?, data: Data?, error: Error?) { print("Response: \(String(describing: response))") }
}
let plugin = MyPlugin()
BioHaazNetworkManager.shared.registerPlugin(plugin)
```

**Objective-C:**
> Plugins must be implemented in Swift, but can be registered from Objective-C if exposed.

---

## 5. Interceptors

**Purpose:** Modify requests and responses globally (e.g., add headers, log, handle errors).

**How it works:**
- Implement the `BioHaazInterceptor` protocol in Swift.
- Register interceptors via config.

**Swift:**
```swift
class MyInterceptor: BioHaazInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest {
        var req = request
        req.setValue("MyValue", forHTTPHeaderField: "X-My-Header")
        return req
    }
    func intercept(_ response: URLResponse?, data: Data?, error: Error?) {
        print("Intercepted response: \(String(describing: response))")
    }
}
let interceptor = MyInterceptor()
let config = BioHaazNetworkConfig(
    // ...
    interceptors: [interceptor]
)
```

**Objective-C:**
> Interceptors must be implemented in Swift, but can be registered from Objective-C if exposed.

---

## 6. Performance Tracking

**Purpose:** Track API performance metrics for analytics and monitoring.

**How it works:**
- Implement the `BioHaazPerformanceTracker` protocol in Swift.
- Pass an instance via config.

**Swift:**
```swift
class MyTracker: BioHaazPerformanceTracker {
    func track(request: URLRequest, duration: TimeInterval, success: Bool, speed: Double?) {
        print("Tracked: \(request.url?.absoluteString ?? "") in \(duration)s, success: \(success), speed: \(speed ?? 0)")
    }
}
let tracker = MyTracker()
let config = BioHaazNetworkConfig(
    // ...
    performanceTracker: tracker
)
```

**Objective-C:**
> Trackers must be implemented in Swift, but can be registered from Objective-C if exposed.

---

## 7. Offline Queue

**Purpose:** Ensure POST, PUT, PATCH, and DELETE requests are not lost when offline; queue and process manually or automatically.

**How it works:**
- Enable `autoOfflineProcess` in config (default is true).
- POST, PUT, PATCH, and DELETE requests are queued when offline.
- Queue is automatically processed when app becomes active (if `autoOfflineProcess` is enabled).
- You can also manually process the queue using `processOfflineQueue()`.

**Swift - Manual Queue Processing:**
```swift
// Process offline queue manually
BioHaazNetworkManager.shared.processOfflineQueue { result in
    switch result {
    case .success(let processingResult):
        print("Processed: \(processingResult.processedCount), Failed: \(processingResult.failedCount), Remaining: \(processingResult.remainingCount)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}

// Check queue status
let status = BioHaazNetworkManager.shared.getOfflineQueueStatus()
let queueCount = status["offlineRequestsCount"] as? Int ?? 0

// Or use simple status check
let (count, hasItems) = BioHaazNetworkManager.shared.checkOfflineQueueStatus()

// Clear the queue
let clearResult = BioHaazNetworkManager.shared.clearOfflineQueue()
```

**Swift - Direct Queue Access (Advanced):**
```swift
// Add a request manually
BioHaazOfflineQueue.shared.add(request)

// Process the queue manually (low-level)
BioHaazOfflineQueue.shared.processQueue { request in
    BioHaazNetworkManager.shared.sendQueuedRequest(request)
}

// Clear the queue (low-level)
BioHaazOfflineQueue.shared.clear()
```

**Objective-C:**
```objc
// Process offline queue
[[BioHaazNetworkManager shared] processOfflineQueueWithForce:NO completion:^(id result, BioHaazNetworkError *error) {
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
    } else {
        // Handle result
    }
}];

// Check queue status
NSDictionary *status = [[BioHaazNetworkManager shared] getOfflineQueueStatus];
NSNumber *queueCount = status[@"offlineRequestsCount"];

// Clear queue
id clearResult = [[BioHaazNetworkManager shared] clearOfflineQueue];
```

---

## 8. Error Handling

**Purpose:** Provide consistent, descriptive errors for all SDK operations.

**How it works:**
- All errors are returned as `BioHaazNetworkError`.
- Use `localizedDescription` for user-friendly messages.

**Swift:**
```swift
case .failure(let error):
    print(error.localizedDescription)
```

**Objective-C:**
```objc
if (error) {
    NSLog(@"%@", error.localizedDescription);
}
```

---

## 9. File Upload/Download

**Purpose:** Upload and download files with progress and error handling.

**How it works:**
- Use `uploadFile` and `downloadFile` methods on the manager.

**Swift (Upload):**
```swift
let fileData = ... // Data to upload
BioHaazNetworkManager.shared.uploadFile(
    url: "/upload",
    fileData: fileData,
    fileName: "photo.jpg",
    mimeType: "image/jpeg"
) { result in
    // Handle result
}
```

**Swift (Download):**
```swift
let destinationURL = ... // Local file URL
BioHaazNetworkManager.shared.downloadFile(
    from: "/file.zip",
    to: destinationURL,
    progress: { progress in
        print("Progress: \(progress)")
    },
    completion: { result in
        // Handle result
    }
)
```

**Objective-C:**
```objc
NSData *fileData = ...; // Data to upload
[[BioHaazNetworkManager shared] uploadFileWithUrl:@"/upload"
                                         fileData:fileData
                                         fileName:@"photo.jpg"
                                         mimeType:@"image/jpeg"
                                         headers:nil
                                       completion:^(id result, BioHaazNetworkError *error) {
    // Handle result
}];

NSURL *destinationURL = ...; // Local file URL
[[BioHaazNetworkManager shared] downloadFileFrom:@"/file.zip"
                                              to:destinationURL
                                         progress:^(double progress) {
    NSLog(@"Progress: %f", progress);
} completion:^(NSURL *fileURL, BioHaazNetworkError *error) {
    // Handle result
}];
```

---

## 10. Image Loading

**Purpose:** Load images into `UIImageView` from a URL with placeholder, error image, and retry support.

**How it works:**
- Use the `bh_setImage` extension on `UIImageView` (Swift only).

**Swift:**
```swift
imageView.bh_setImage(
    from: "https://example.com/image.jpg",
    placeholder: UIImage(named: "placeholder"),
    errorImage: UIImage(named: "error"),
    enableRetry: true
)
```

**Objective-C:**
> The `bh_setImage` extension is only available in Swift. For Objective-C, use a custom image loading approach or bridge this extension.

---

## 11. Advanced Features

- **Token Refresh:** Handled internally; see SDK source for custom provider integration.
- **Secure Storage:** Uses Keychain for token storage.
- **Retry Policy:** Automatic retry for certain errors; see `BioHaazRetryPolicy` for customization.
- **Debug Mode:** Enable `debug` in config for verbose logs.

---

## 12. HTTP Methods (GET, POST, PUT, DELETE)

**Purpose:** Perform RESTful API requests.

**How it works:**
- Use the `request` method on the manager.

**Swift:**
```swift
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users",
    headers: nil,
    params: nil
) { result in
    // Handle result
}
```

**Objective-C:**
```objc
[[BioHaazNetworkManager shared] requestWithMethod:@"GET"
                                              url:@"/users"
                                          headers:nil
                                           params:nil
                                         completion:^(id result, BioHaazNetworkError *error) {
    // Handle result
}];
```

---

## 13. Summary Table

| Topic                | Swift Example | Objective-C Example |
|----------------------|--------------|--------------------|
| Initialization       | See above    | See above          |
| Environments         | See above    | See above          |
| Logging              | See above    | See above          |
| Plugins              | See above    | Register Swift     |
| Interceptors         | See above    | Register Swift     |
| Performance Tracking | See above    | Register Swift     |
| Offline Queue        | See above    | Register Swift     |
| Error Handling       | See above    | See above          |
| File Upload/Download | See above    | See above          |
| Image Loading        | See above    | Use custom/bridge  |
| Advanced Features    | See above    | See above          |
| HTTP Methods         | See above    | See above          | 