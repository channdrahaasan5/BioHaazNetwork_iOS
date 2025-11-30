# BioHaazNetwork iOS SDK - API Reference

## Table of Contents
1. [BioHaazNetworkManager](#biohaaznetworkmanager)
2. [BioHaazNetworkConfig](#biohaaznetworkconfig)
3. [BioHaazNetworkError](#biohaaznetworkerror)
4. [BioHaazOfflineQueue](#biohaazofflinequeue)
5. [BioHaazLogger](#biohaazlogger)
6. [BioHaazNotificationService](#biohaaznotificationservice)
7. [BioHaazBackgroundProcessor](#biohaazbackgroundprocessor)
8. [Protocols](#protocols)
9. [Extensions](#extensions)

## BioHaazNetworkManager

The main entry point for the BioHaazNetwork SDK.

### Properties

```swift
public static let shared: BioHaazNetworkManager
```

### Initialization

```swift
public func initialize(config: BioHaazNetworkConfig)
```

### HTTP Methods

#### GET Request
```swift
public func get(
    endpoint: String,
    headers: [String: String]? = nil,
    queryParams: [String: String]? = nil,
    completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
)
```

#### POST Request
```swift
public func post(
    endpoint: String,
    body: Any? = nil,
    headers: [String: String]? = nil,
    completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
)
```

#### PUT Request
```swift
public func put(
    endpoint: String,
    body: Any? = nil,
    headers: [String: String]? = nil,
    completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
)
```

#### DELETE Request
```swift
public func delete(
    endpoint: String,
    headers: [String: String]? = nil,
    completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
)
```

### File Operations

#### Upload File
```swift
public func uploadFile(
    url: String,
    fileData: Data,
    fileName: String,
    mimeType: String,
    headers: [String: String]? = nil,
    completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
)
```

#### Download File
```swift
public func downloadFile(
    from url: String,
    to destinationURL: URL,
    progress: @escaping (Double) -> Void,
    completion: @escaping (Result<URL, BioHaazNetworkError>) -> Void
)
```

### Environment Management

```swift
public func setEnvironment(_ environment: BioHaazEnvironment)
public func getCurrentEnvironment() -> BioHaazEnvironment
public func getBaseURL() -> String?
```

### Plugin Management

```swift
public func registerPlugin(_ plugin: BioHaazPlugin)
public func unregisterPlugin(_ plugin: BioHaazPlugin)
```

### Interceptor Management

```swift
public func addRequestInterceptor(_ interceptor: @escaping (URLRequest) -> URLRequest)
public func addResponseInterceptor(_ interceptor: @escaping (URLResponse?, Data?, Error?) -> (URLResponse?, Data?, Error?))
```

### Offline Queue Processing

#### Process Offline Queue (Recommended)
Manually process offline queue when app wakes up via push notifications, location updates, or other background modes. This is more reliable than iOS background fetch.

```swift
public func processOfflineQueue(
    force: Bool = false,
    completion: ((Result<OfflineQueueProcessingResult, BioHaazNetworkError>) -> Void)? = nil
)
```

**Parameters:**
- `force`: If `true`, processes queue even if network appears unavailable (default: `false`)
- `completion`: Optional completion handler with detailed processing results

**Returns:** `Result<OfflineQueueProcessingResult, BioHaazNetworkError>`

**Example:**
```swift
// In push notification handler
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

#### Check Offline Queue Status
Quick check to see if there are items in the offline queue without processing.

```swift
public func checkOfflineQueueStatus() -> (count: Int, hasItems: Bool)
```

**Returns:** Tuple with queue count and whether queue has items

**Example:**
```swift
let status = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
if status.hasItems {
    print("\(status.count) items in queue")
}
```

#### Get Background Processing Status
```swift
public func getBackgroundProcessingStatus() -> [String: Any]
```

#### Trigger Background Processing (Deprecated)
```swift
@available(*, deprecated, message: "Use processOfflineQueue() instead")
public func triggerBackgroundProcessing()
```

## BioHaazNetworkConfig

Configuration class for the BioHaazNetwork SDK.

### Properties

```swift
public let baseURL: String
public let environments: [BioHaazEnvironment: String]?
public let defaultEnvironment: BioHaazEnvironment?
public let sslPinningEnabled: Bool
public let pinnedCertificates: [String: String]?
public let loggingEnabled: Bool
public let debug: Bool
public let logRetentionDays: Int
public let timeout: TimeInterval
public let retryCount: Int
public let retryDelay: TimeInterval
public let mockMode: Bool
public let plugins: [BioHaazPlugin]
public let interceptors: [BioHaazInterceptor]
public let performanceTracker: BioHaazPerformanceTracker?
public let autoOfflineProcess: Bool
public let offlineNotificationService: Bool
public let notificationTitle: String
public let notificationBody: String
public let enableBackgroundFetch: Bool
```

**Note:** `enableBackgroundFetch` defaults to `true`. Both background fetch and manual processing via `processOfflineQueue()` work together for comprehensive offline queue handling.

### Initializers

#### Basic Initializer
```swift
public init(
    baseURL: String,
    debug: Bool = false,
    autoOfflineProcess: Bool = true,
    offlineNotificationService: Bool = false,
    notificationTitle: String = "Network Status",
    notificationBody: String = "Your request has been processed",
    timeout: TimeInterval = 30.0,
    retryCount: Int = 3,
    retryDelay: TimeInterval = 1.0
)
```

#### Advanced Initializer
```swift
public init(
    environments: [BioHaazEnvironment: String],
    defaultEnvironment: BioHaazEnvironment,
    sslPinningEnabled: Bool = false,
    pinnedCertificates: [String: String]? = nil,
    loggingEnabled: Bool = true,
    debug: Bool = false,
    logRetentionDays: Int = 7,
    timeout: TimeInterval = 60.0,
    retryCount: Int = 3,
    retryDelay: TimeInterval = 2.0,
    mockMode: Bool = false,
    plugins: [BioHaazPlugin] = [],
    interceptors: [BioHaazInterceptor] = [],
    performanceTracker: BioHaazPerformanceTracker? = nil,
    autoOfflineProcess: Bool = true,
    offlineNotificationService: Bool = false,
    notificationTitle: String = "Network Status",
    notificationBody: String = "Your request has been processed"
)
```

## BioHaazNetworkError

Error types for the BioHaazNetwork SDK.

### Cases

```swift
public enum BioHaazNetworkError: Error {
    case noNetwork
    case invalidURL
    case timeout
    case serverError(Int)
    case decodingError
    case unknown(Error)
}
```

### Properties

```swift
public var localizedDescription: String { get }
```

## BioHaazOfflineQueue

Manages offline request queuing and processing.

### Properties

```swift
public static let shared: BioHaazOfflineQueue
```

### Methods

#### Add Request to Queue
```swift
public func add(
    request: URLRequest,
    priority: OfflineQueuePriority = .normal
) -> Bool
```

#### Process Queue
```swift
public func processQueue(completion: @escaping (URLRequest) -> Void)
```

#### Get Queue Status
```swift
public func getQueueStatus() -> (total: Int, byPriority: [OfflineQueuePriority: Int])
```

#### Clear Queue
```swift
public func clearQueue()
```

### OfflineQueuePriority

```swift
public enum OfflineQueuePriority: Int, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}
```

## BioHaazLogger

Enhanced logging utility for the BioHaazNetwork SDK.

### Properties

```swift
public static let shared: BioHaazLogger
```

### Methods

#### Log API Request
```swift
public func logApiRequest(
    method: String,
    url: String,
    headers: [String: String]?,
    body: Data?,
    requestId: String
)
```

#### Log API Response
```swift
public func logApiResponse(
    method: String,
    url: String,
    statusCode: Int,
    headers: [String: String]?,
    body: Data?,
    duration: TimeInterval,
    requestId: String
)
```

#### Log API Error
```swift
public func logApiError(
    method: String,
    url: String,
    error: Error,
    duration: TimeInterval,
    requestId: String
)
```

#### Log Offline Queue
```swift
public func logOfflineQueue(
    action: String,
    count: Int,
    priority: OfflineQueuePriority?
)
```

#### Log Background Process
```swift
public func logBackgroundProcess(
    action: String,
    details: String
)
```

#### Get Log File URL
```swift
public func getLogFileURL() -> URL
```

## BioHaazNotificationService

Manages notifications for offline request processing.

### Properties

```swift
public static let shared: BioHaazNotificationService
```

### Methods

#### Request Permission
```swift
public func requestNotificationPermission(completion: @escaping (Bool) -> Void)
```

#### Setup Categories
```swift
public func setupNotificationCategories()
```

#### Send Success Notification
```swift
public func sendOfflineRequestProcessedNotification(
    count: Int,
    successCount: Int,
    failureCount: Int
)
```

#### Send Failure Notification
```swift
public func sendOfflineRequestFailedNotification(
    count: Int,
    error: String
)
```

## OfflineQueueProcessingResult

Result structure returned when processing offline queue.

### Properties

```swift
public struct OfflineQueueProcessingResult {
    /// Number of requests successfully processed
    public let processedCount: Int
    
    /// Number of requests that failed (will be retried if retries available)
    public let failedCount: Int
    
    /// Number of requests remaining in queue after processing
    public let remainingCount: Int
    
    /// Total number of requests that were attempted
    public let totalAttempted: Int
}
```

## BioHaazBackgroundProcessor

Handles background processing of offline requests. Works alongside manual processing via `processOfflineQueue()` for comprehensive offline queue handling.

### Properties

```swift
public static let shared: BioHaazBackgroundProcessor
```

### Methods

#### Start Network Monitoring
```swift
public func startNetworkMonitoring()
```

#### Stop Network Monitoring
```swift
public func stopNetworkMonitoring()
```

#### Schedule Background Task
```swift
public func scheduleBackgroundTask()
```

## Protocols

### BioHaazPlugin

```swift
public protocol BioHaazPlugin {
    func onRequest(_ request: URLRequest)
    func onResponse(_ response: URLResponse?, data: Data?, error: Error?)
}
```

### BioHaazInterceptor

```swift
public protocol BioHaazInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest
    func intercept(_ response: URLResponse?, data: Data?, error: Error?)
}
```

### BioHaazPerformanceTracker

```swift
public protocol BioHaazPerformanceTracker {
    func track(request: URLRequest, duration: TimeInterval, success: Bool, speed: Double?)
}
```

## Extensions

### UIImageView Extension

```swift
extension UIImageView {
    public func bh_setImage(
        from urlString: String,
        placeholder: UIImage? = nil,
        errorImage: UIImage? = nil,
        enableRetry: Bool = true
    )
}
```

## BioHaazEnvironment

```swift
public enum BioHaazEnvironment: String, CaseIterable {
    case dev = "dev"
    case qa = "qa"
    case uat = "uat"
    case prod = "prod"
}
```

## BioHaazMockProvider

Manages mock responses for testing.

### Properties

```swift
public static let shared: BioHaazMockProvider
```

### Methods

#### Register Mock
```swift
public func registerMock(
    method: String,
    url: String,
    response: Data,
    statusCode: Int = 200
)
```

#### Clear Mocks
```swift
public func clearMocks()
```

## BioHaazPerformanceReport

```swift
public struct BioHaazPerformanceReport {
    public let url: String
    public let method: String
    public let duration: TimeInterval
    public let success: Bool
    public let speed: Double?
}
```

## BioHaazRetryPolicy

```swift
public class BioHaazRetryPolicy {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        multiplier: Double = 2.0
    )
}
```

## BioHaazSSLDelegate

```swift
public class BioHaazSSLDelegate: NSObject, URLSessionDelegate {
    public init(pinnedCertificates: [String: String]?)
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
}
```

## BioHaazKeychain

Secure storage utility for tokens and sensitive data.

### Methods

#### Store Data
```swift
public func store(_ data: Data, forKey key: String) -> Bool
```

#### Retrieve Data
```swift
public func retrieve(forKey key: String) -> Data?
```

#### Delete Data
```swift
public func delete(forKey key: String) -> Bool
```

## BioHaazJSONDecoder

Custom JSON decoder with enhanced error handling.

### Methods

#### Decode with Error Handling
```swift
public func decode<T: Decodable>(
    _ type: T.Type,
    from data: Data
) throws -> T
```

## BioHaazPerformanceTracker

Default implementation of the performance tracker protocol.

```swift
public class BioHaazDefaultPerformanceTracker: BioHaazPerformanceTracker {
    public var onReport: ((BioHaazPerformanceReport) -> Void)?
    
    public init(onReport: ((BioHaazPerformanceReport) -> Void)? = nil)
    
    public func track(
        request: URLRequest,
        duration: TimeInterval,
        success: Bool,
        speed: Double?
    )
}
```

---

This API reference provides a comprehensive overview of all public interfaces in the BioHaazNetwork iOS SDK. For more detailed examples and usage patterns, refer to the [USAGE.md](USAGE.md) documentation.




