# BioHaazNetwork SDK Use Cases & Complete Functionality Guide

This document provides practical use cases and code samples for all major features of the BioHaazNetwork SDK, including initialization, HTTP methods, file upload/download, and image loading.

---

## 1. Initialization

### Swift
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

### Objective-C
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

## 2. GET Request

### Swift
```swift
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users",
    headers: ["Authorization": "Bearer <token>"],
    params: nil
) { result in
    switch result {
    case .success(let data):
        // Handle data
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

### Objective-C
```objc
[[BioHaazNetworkManager shared] requestWithMethod:@"GET"
                                              url:@"/users"
                                          headers:@{@"Authorization": @"Bearer <token>"}
                                           params:nil
                                         completion:^(id result, BioHaazNetworkError *error) {
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    } else {
        // Handle data
    }
}];
```

---

## 3. POST Request

### Swift
```swift
let params = ["name": "John", "email": "john@example.com"]
BioHaazNetworkManager.shared.request(
    method: "POST",
    url: "/users",
    headers: nil,
    params: params
) { result in
    // Handle result
}
```

### Objective-C
```objc
NSDictionary *params = @{@"name": @"John", @"email": @"john@example.com"};
[[BioHaazNetworkManager shared] requestWithMethod:@"POST"
                                              url:@"/users"
                                          headers:nil
                                           params:params
                                         completion:^(id result, BioHaazNetworkError *error) {
    // Handle result
}];
```

---

## 4. PUT Request

### Swift
```swift
let params = ["email": "newemail@example.com"]
BioHaazNetworkManager.shared.request(
    method: "PUT",
    url: "/users/123",
    headers: nil,
    params: params
) { result in
    // Handle result
}
```

### Objective-C
```objc
NSDictionary *params = @{@"email": @"newemail@example.com"};
[[BioHaazNetworkManager shared] requestWithMethod:@"PUT"
                                              url:@"/users/123"
                                          headers:nil
                                           params:params
                                         completion:^(id result, BioHaazNetworkError *error) {
    // Handle result
}];
```

---

## 5. DELETE Request

### Swift
```swift
BioHaazNetworkManager.shared.request(
    method: "DELETE",
    url: "/users/123",
    headers: nil,
    params: nil
) { result in
    // Handle result
}
```

### Objective-C
```objc
[[BioHaazNetworkManager shared] requestWithMethod:@"DELETE"
                                              url:@"/users/123"
                                          headers:nil
                                           params:nil
                                         completion:^(id result, BioHaazNetworkError *error) {
    // Handle result
}];
```

---

## 6. File Upload (uploadFile)

### Swift
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

### Objective-C
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
```

---

## 7. File Download (downloadFile)

### Swift
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

### Objective-C
```objc
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

## 8. Image Loading (UIImageView Extension)

### Swift
```swift
import UIKit
imageView.bh_setImage(
    from: "https://example.com/image.jpg",
    placeholder: UIImage(named: "placeholder"),
    errorImage: UIImage(named: "error"),
    enableRetry: true
)
```

### Objective-C
> **Note:** The `bh_setImage` extension is only available in Swift. For Objective-C, use a custom image loading approach or bridge this extension.

---

## 9. Error Handling

All errors are returned as `BioHaazNetworkError`. You can access a user-friendly message via `error.localizedDescription`.

### Swift
```swift
case .failure(let error):
    print(error.localizedDescription)
```

### Objective-C
```objc
if (error) {
    NSLog(@"%@", error.localizedDescription);
}
```

---

## 10. Advanced Features

- **Plugins, Interceptors, Performance Tracker:** See `SDKInitialization.md` for advanced usage and registration.
- **Offline Queue:** Enable `autoOfflineProcess` to queue POSTs when offline.
- **Logging:** Use `loggingEnabled` in config and `BioHaazLogger` for custom logs.

---

## 11. Summary Table

| Feature         | Swift Example | Objective-C Example |
|-----------------|--------------|--------------------|
| Initialize      | See above    | See above          |
| GET/POST/PUT/DELETE | See above | See above          |
| uploadFile      | See above    | See above          |
| downloadFile    | See above    | See above          |
| Image Load      | See above    | Use custom/bridge  |
| Error Handling  | See above    | See above          |
| Advanced        | See SDKInitialization.md | See SDKInitialization.md | 

---

## 12. How Offline Process Works

The **offline process** in the BioHaazNetwork SDK ensures that important POST requests are not lost when the device is offline.

### 1. Enabling Offline Process
- Controlled by the `autoOfflineProcess` parameter in `BioHaazNetworkConfig`.
- Set `autoOfflineProcess: true` (default is true).

### 2. What Happens When Offline?
- When you make a POST request and the device is **offline**:
  - The SDK **does not send** the request immediately.
  - Instead, it **queues** the request using the `BioHaazOfflineQueue` utility.
  - The request is stored locally (using `UserDefaults`).

### 3. Automatic Processing When App Becomes Active
- The SDK monitors app lifecycle events.
- When the app becomes **active** (if `autoOfflineProcess` is enabled):
  - The SDK automatically **processes the offline queue**.
  - All queued POST requests are sent in priority order (Critical → High → Normal → Low).
- The SDK also monitors network status and processes the queue when network is restored.

### 4. Queue Management
- The queue is persistent (survives app restarts).
- Maximum queue size: 1000 items.
- You can manually process, check status, or clear the queue using `BioHaazNetworkManager` methods.
- Recommended: Process queue manually when app wakes up from background services (push notifications, location updates, etc.).

### Code Flow (Simplified)

1. **POST Request While Offline**
   ```swift
   // This is handled internally by the SDK:
   if config.autoOfflineProcess, !isNetworkAvailable, method.uppercased() == "POST" {
       _ = BioHaazOfflineQueue.shared.add(request)
       completion(.failure(BioHaazNetworkError.noNetwork))
       return
   }
   ```

2. **Automatic Processing**
   - The SDK monitors app lifecycle and network status.
   - When app becomes active or network is restored, it calls:
     ```swift
     BioHaazNetworkManager.shared.processOfflineQueue { result in
         // Handle processing result
     }
     ```

3. **Processing the Queue**
   - Each queued request is sent using the normal network flow.

### Example Scenario

1. **User tries to submit a form (POST) while offline.**
2. The request is **queued**.
3. When app becomes active or network is restored (if `autoOfflineProcess` is enabled):
   - The SDK **automatically processes** the queued request(s).
4. Alternatively, you can **manually process** the queue when app wakes up from background services.

### Manual Queue Processing

You can manually process the offline queue at any time, which is recommended when:
- App wakes up from background (location updates, push notifications, etc.)
- User manually triggers a sync
- App becomes active

#### Swift - Recommended Approach
```swift
// Process offline queue manually
BioHaazNetworkManager.shared.processOfflineQueue { result in
    switch result {
    case .success(let processingResult):
        print("✅ Processed: \(processingResult.processedCount)")
        print("❌ Failed: \(processingResult.failedCount)")
        print("📦 Remaining: \(processingResult.remainingCount)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}

// Check queue status before processing
let (count, hasItems) = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
if hasItems {
    print("Queue has \(count) items - processing...")
    BioHaazNetworkManager.shared.processOfflineQueue { _ in }
}

// Get detailed queue status
let status = BioHaazNetworkManager.shared.getOfflineQueueStatus()
let queueCount = status["offlineRequestsCount"] as? Int ?? 0
let statistics = status["queueStatistics"] as? [String: Any]

// Clear the queue if needed
let clearResult = BioHaazNetworkManager.shared.clearOfflineQueue()
```

#### Example: Process Queue on App Activation
```swift
func applicationDidBecomeActive(_ application: UIApplication) {
    // Process offline queue when app becomes active
    let queueStatus = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
    if queueStatus.hasItems {
        BioHaazNetworkManager.shared.processOfflineQueue { result in
            switch result {
            case .success(let processingResult):
                print("Processed \(processingResult.processedCount) requests")
            case .failure(let error):
                print("Failed: \(error.localizedDescription)")
            }
        }
    }
}
```

#### Example: Process Queue from Push Notification
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, 
                           didReceive response: UNNotificationResponse, 
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    // Process queue when app wakes up from notification
    BioHaazNetworkManager.shared.processOfflineQueue { _ in }
    completionHandler()
}
```

#### Advanced: Direct Queue Access (Low-Level)
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

#### Objective-C
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

### Summary Table

| Step                | What Happens                                      |
|---------------------|---------------------------------------------------|
| POST while offline  | Request is queued, not sent                       |
| App becomes active  | Queue is automatically processed (if `autoOfflineProcess` is enabled) |
| Network returns     | Queue is automatically processed (if `autoOfflineProcess` is enabled) |
| Manual processing   | Call `processOfflineQueue()` when app wakes up (recommended) |
| Queue status        | Use `checkOfflineQueueStatus()` or `getOfflineQueueStatus()` |
| Clear queue         | Use `clearOfflineQueue()` to remove all queued requests |

**In short:**  
The offline process ensures reliability for POST requests by queuing them when offline. The queue is automatically processed when the app becomes active (if enabled), or you can manually process it when the app wakes up from background services like push notifications or location updates. 
