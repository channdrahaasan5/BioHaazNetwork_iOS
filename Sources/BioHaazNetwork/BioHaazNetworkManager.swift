//
//  BioHaazNetworkManager.swift
//  BioHaazNetwork
//
//  Main entry point for the BioHaazNetwork SDK
//

import Foundation
import UIKit
import Network
import Combine

// MARK: - Environment Enum
public enum BioHaazEnvironment: String {
    case dev, qa, uat, prod
}

// MARK: - Config Object
public struct BioHaazNetworkConfig {
    public let environments: [BioHaazEnvironment: String]
    public var defaultEnvironment: BioHaazEnvironment
    // Hidden for this release - will be made public in next release
    internal var sslPinningEnabled: Bool
    internal var pinnedCertificates: [String: String]?
    public var loggingEnabled: Bool
    public var timeout: TimeInterval
    // Hidden for this release - will be made public in next release
    internal var mockMode: Bool
    public var plugins: [BioHaazPlugin]
    public var interceptors: [BioHaazInterceptor]
    public var performanceTracker: BioHaazPerformanceTracker?
    public var autoOfflineProcess: Bool
    public var debug: Bool
    // MARK: - Notification Service (Commented for next version)
    // public var offlineNotificationService: Bool
    // public var notificationTitle: String
    // public var notificationBody: String
     
    public init(
        environments: [BioHaazEnvironment: String],
        defaultEnvironment: BioHaazEnvironment = .prod,
        // sslPinningEnabled: Bool = false, // Hidden for this release
        // pinnedCertificates: [String: String]? = nil, // Hidden for this release
        loggingEnabled: Bool = false,
        timeout: TimeInterval = 30,
        // mockMode: Bool = false, // Hidden for this release
        plugins: [BioHaazPlugin] = [],
        interceptors: [BioHaazInterceptor] = [],
        //performanceTracker: BioHaazPerformanceTracker? = nil,
        autoOfflineProcess: Bool = true,
        debug: Bool = false
        // MARK: - Notification Service (Commented for next version)
        // offlineNotificationService: Bool = false,
        // notificationTitle: String = "Offline Request Processed",
        // notificationBody: String = "Your offline request has been successfully processed"
    ) {
        self.environments = environments
        self.defaultEnvironment = defaultEnvironment
        // Set internal defaults for hidden features
        self.sslPinningEnabled = false // Internal default for this release
        self.pinnedCertificates = nil // Internal default for this release
        self.loggingEnabled = loggingEnabled
        self.timeout = timeout
        self.mockMode = false // Internal default for this release
        self.plugins = plugins
        self.interceptors = interceptors
        //self.performanceTracker = performanceTracker
        self.autoOfflineProcess = autoOfflineProcess
        self.debug = debug
        // MARK: - Notification Service (Commented for next version)
        // self.offlineNotificationService = offlineNotificationService
        // self.notificationTitle = notificationTitle
        // self.notificationBody = notificationBody
    }
}

// MARK: - Plugin Protocol
public protocol BioHaazPlugin {
    func onRequest(_ request: URLRequest)
    func onResponse(_ response: URLResponse?, data: Data?, error: Error?)
}

// MARK: - Interceptor Protocol
public protocol BioHaazInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest
    func intercept(_ response: URLResponse?, data: Data?, error: Error?)
}

// MARK: - Performance Tracker Protocol
public protocol BioHaazPerformanceTracker {
    func track(request: URLRequest, duration: TimeInterval, success: Bool, speed: Double?)
}

// MARK: - Offline Queue Processing Result
/// Result structure returned when processing offline queue
public struct OfflineQueueProcessingResult {
    /// Number of requests successfully processed
    public let processedCount: Int
    /// Number of requests that failed (will be retried if retries available)
    public let failedCount: Int
    /// Number of requests remaining in queue after processing
    public let remainingCount: Int
    /// Total number of requests that were attempted
    public let totalAttempted: Int
    
    public init(processedCount: Int, failedCount: Int, remainingCount: Int, totalAttempted: Int) {
        self.processedCount = processedCount
        self.failedCount = failedCount
        self.remainingCount = remainingCount
        self.totalAttempted = totalAttempted
    }
}

/// The main entry point for BioHaazNetwork SDK. Manages all network operations, configuration, plugins, and advanced features.
public class BioHaazNetworkManager {
    /// Shared singleton instance of the network manager.
    public static let shared = BioHaazNetworkManager()
    
    /// The current SDK configuration.
    private(set) var config: BioHaazNetworkConfig?
    /// The currently active environment.
    private(set) var currentEnvironment: BioHaazEnvironment?
    
    // Token provider, secure storage, offline queue, etc.
    private var tokenProvider: BioHaazTokenProvider?
    private var offlineQueue: [URLRequest] = []
    private var duplicateRequestCache: Set<String> = []
    
    private var sslDelegate: BioHaazSSLDelegate?
    private var urlSession: URLSession = URLSession.shared
    
    private var isRefreshingToken = false
    private var pendingRequests: [(()->Void)] = []
    
    private var retryPolicy = BioHaazRetryPolicy()
    
    private var pathMonitor: NWPathMonitor?
    private var isNetworkAvailable: Bool = true
    
    private var inProgressTasks: [String: URLSessionDataTask] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var isProcessingQueue = false
    
    private init() {
        // Listen for app lifecycle events to process offline queue
        setupAppLifecycleListener()
    }
    
    /// Initializes the SDK with the provided configuration.
    /// - Parameter config: The configuration object containing all SDK settings.
    public func initialize(with config: BioHaazNetworkConfig) {
        self.config = config
        self.currentEnvironment = config.defaultEnvironment
        
        // Setup enhanced logging
        BioHaazLogger.shared.configure(debug: config.debug, retentionDays: 7)
        
        // Setup SSL pinning, logging, plugins, etc.
        if config.sslPinningEnabled {
            // SSL Pinning functionality - available but disabled by default for this release
            self.sslDelegate = BioHaazSSLDelegate(pinnedCertificates: config.pinnedCertificates)
            let sessionConfig = URLSessionConfiguration.default
            self.urlSession = URLSession(configuration: sessionConfig, delegate: sslDelegate, delegateQueue: nil)
        } else {
            self.urlSession = URLSession.shared
        }
        
        // Setup network monitoring for auto offline process
        if config.autoOfflineProcess {
            setupNetworkMonitor()
            // Process offline queue on initialization if network is available
            if isNetworkAvailable {
                processOfflineQueueOnAppOpen()
            }
        }
    }
    
    /// Setup app lifecycle listener to process offline queue when app opens
    private func setupAppLifecycleListener() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let config = self.config, config.autoOfflineProcess {
                    // Process offline queue when app comes to foreground
                    self.processOfflineQueueOnAppOpen()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let config = self.config, config.autoOfflineProcess {
                    // Also process on active state
                    self.processOfflineQueueOnAppOpen()
                }
            }
            .store(in: &cancellables)
        
    }
    
    /// Process offline queue automatically when app opens and network is available
    private func processOfflineQueueOnAppOpen() {
        // Use the public method for consistency
        processOfflineQueue(force: false) { [weak self] result in
            guard let self = self, let config = self.config else { return }
            
            switch result {
            case .success(let processingResult):
                if config.debug {
                    BioHaazLogger.shared.log("[OFFLINE] Auto-processing on app open completed: \(processingResult.processedCount) processed", level: "SUCCESS")
                }
            case .failure(let error):
                if config.debug {
                    BioHaazLogger.shared.log("[OFFLINE] Auto-processing on app open failed: \(error.localizedDescription)", level: "WARNING")
                }
            }
        }
    }
    
    private func setupNetworkMonitor() {
        pathMonitor = NWPathMonitor()
        let queue = DispatchQueue(label: "BioHaazNetworkPathMonitor")
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let wasNetworkAvailable = self.isNetworkAvailable
            self.isNetworkAvailable = path.status == .satisfied
            
            // Process offline queue when network comes back online
            if self.isNetworkAvailable && !wasNetworkAvailable {
                self.processOfflineQueueOnAppOpen()
            }
        }
        pathMonitor?.start(queue: queue)
    }
    
    /// Helper to send queued requests
    public func sendQueuedRequest(_ request: URLRequest) {
        let task = urlSession.dataTask(with: request) { _, _, _ in }
        task.resume()
    }
    
    // MARK: - Multi-Environment Support
    /// Sets the current environment (e.g., dev, qa, prod).
    /// - Parameter environment: The environment to switch to.
    public func setEnvironment(_ environment: BioHaazEnvironment) {
        self.currentEnvironment = environment
    }
    
    /// Returns the current environment.
    public func getCurrentEnvironment() -> BioHaazEnvironment? {
        return self.currentEnvironment
    }
    
    /// Returns the base URL for the current environment.
    public func getBaseURL() -> String? {
        guard let config = config else { return nil }
        return config.environments[currentEnvironment ?? config.defaultEnvironment]
    }
    
    // MARK: - Helper: Build URLRequest
    private func buildRequest(
        method: String,
        url: String,
        headers: [String: String]?,
        params: [String: Any]?
    ) -> URLRequest? {
        guard let config = config, let baseURL = config.environments[currentEnvironment ?? config.defaultEnvironment], let fullURL = URL(string: baseURL + url) else {
            return nil
        }
        var request = URLRequest(url: fullURL)
        request.httpMethod = method.uppercased()
        request.timeoutInterval = config.timeout
        // Inject headers
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        // Token injection
        if let token = tokenProvider?.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Encode params for POST/PUT
        if let params = params, method.uppercased() != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        }
        // Interceptors (request)
        config.interceptors.forEach { request = $0.intercept(request) }
        return request
    }

    private func requestKey(method: String, url: String, params: [String: Any]?) -> String {
        let paramsString: String
        if let params = params, let data = try? JSONSerialization.data(withJSONObject: params, options: [.sortedKeys]), let str = String(data: data, encoding: .utf8) {
            paramsString = str
        } else {
            paramsString = ""
        }
        return "\(method.uppercased())|\(url)|\(paramsString)"
    }

    // MARK: - Core Networking Methods
    /// Makes a REST API request (GET, POST, PUT, DELETE).
    /// - Parameters:
    ///   - method: HTTP method ("GET", "POST", etc.)
    ///   - url: Endpoint path (relative to base URL)
    ///   - headers: Optional HTTP headers
    ///   - params: Optional parameters (for POST/PUT)
    ///   - attempt: Internal use for retry logic
    ///   - completion: Completion handler with Result<Data, BioHaazNetworkError>
    public func request(
        method: String,
        url: String,
        headers: [String: String]? = nil,
        params: [String: Any]? = nil,
        attempt: Int = 0,
        completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
    ) {
        guard let config = config else {
            completion(.failure(BioHaazNetworkError.notInitialized))
            return
        }
        // Mock mode: return mock response if available (disabled by default for this release)
        if config.mockMode, let mockData = BioHaazMockProvider.shared.getMock(method: method, url: url) {
            if config.debug { BioHaazLogger.shared.log("[MOCK] \(method) \(url) -> \(mockData.count) bytes", level: "MOCK") }
            completion(.success(mockData))
            return
        }
        guard let request = buildRequest(method: method, url: url, headers: headers, params: params) else {
            if config.debug { BioHaazLogger.shared.log("[ERROR] Invalid URL or config for \(method) \(url)", level: "ERROR") }
            completion(.failure(BioHaazNetworkError.invalidURL))
            return
        }
        // Offline queueing for POST, PUT, PATCH, DELETE requests
        let methodUpper = method.uppercased()
        let queueableMethods = ["POST", "PUT", "PATCH", "DELETE"]
        if config.autoOfflineProcess, !isNetworkAvailable, queueableMethods.contains(methodUpper) {
            _ = BioHaazOfflineQueue.shared.add(request)
            if config.debug { BioHaazLogger.shared.log("[QUEUE] Queued \(methodUpper) \(url) due to no network", level: "QUEUE") }
            completion(.failure(BioHaazNetworkError.noNetwork))
            return
        }
        // Enhanced logging
        let requestId = UUID().uuidString.prefix(8)
        if config.debug {
            BioHaazLogger.shared.logApiRequest(
                method: method,
                url: url,
                headers: headers,
                body: request.httpBody,
                requestId: String(requestId)
            )
        }
        // Plugins (onRequest)
        config.plugins.forEach { $0.onRequest(request) }
        let startTime = Date()
        let key = requestKey(method: method, url: url, params: params)
        // Auto-cancel duplicate requests
        if let existingTask = inProgressTasks[key] {
            existingTask.cancel()
            inProgressTasks.removeValue(forKey: key)
            if config.debug { BioHaazLogger.shared.log("[DUPLICATE] Cancelled previous in-progress request for \(key)", level: "DUPLICATE") }
        }
        let executeRequest: () -> Void = { [weak self] in
            guard let self = self else { return }
            let task = self.urlSession.dataTask(with: request) { data, response, error in
                let duration = Date().timeIntervalSince(startTime)
                // Plugins (onResponse)
                config.plugins.forEach { $0.onResponse(response, data: data, error: error) }
                // Interceptors (response)
                config.interceptors.forEach { $0.intercept(response, data: data, error: error) }
                // Enhanced response logging
                if config.debug {
                    if let httpResponse = response as? HTTPURLResponse {
                        let responseHeaders: [String: String] = Dictionary(uniqueKeysWithValues: httpResponse.allHeaderFields.compactMap { key, value in
                            guard let stringKey = key as? String, let stringValue = value as? String else { return nil }
                            return (stringKey, stringValue)
                        })
                        BioHaazLogger.shared.logApiResponse(
                            method: method,
                            url: url,
                            statusCode: httpResponse.statusCode,
                            headers: responseHeaders,
                            body: data,
                            duration: duration,
                            requestId: String(requestId)
                        )
                    } else if let error = error {
                        BioHaazLogger.shared.logApiError(
                            method: method,
                            url: url,
                            error: error,
                            requestId: String(requestId)
                        )
                    }
                }
                // Performance tracking
                config.performanceTracker?.track(request: request, duration: duration, success: (error == nil), speed: data != nil ? Double(data!.count) / duration : nil)
                // Token refresh logic
                if let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 401 || httpResponse.statusCode == 403),    self.tokenProvider != nil {
                    if config.debug {
                        BioHaazLogger.shared.log("[TOKEN] Refresh triggered for \(method) \(url)", level: "TOKEN")
                    }
                    self.handleTokenRefresh {
                        // Retry the original request once after refresh
                        self.request(method: method, url: url, headers: headers, params: params, completion: completion)
                    } failure: {
                        if config.debug {
                            BioHaazLogger.shared.log("[TOKEN] Refresh failed for \(method) \(url)", level: "TOKEN")
                        }
                        completion(.failure(BioHaazNetworkError.tokenRefreshFailed))
                    }
                    return
                }
                // Retry logic
                if self.retryPolicy.shouldRetry(method: method, error: error, response: response, attempt: attempt) {
                    let delay = self.retryPolicy.nextDelay(attempt: attempt)
                    if config.debug { BioHaazLogger.shared.log("[RETRY] \(method) \(url) Attempt: \(attempt+1) Delay: \(delay)s", level: "RETRY") }
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.request(method: method, url: url, headers: headers, params: params, attempt: attempt + 1, completion: completion)
                    }
                    return
                }
                // Error handling
                if let error = error {
                    if config.debug { BioHaazLogger.shared.log("[ERROR] \(method) \(url) Error: \(error.localizedDescription)", level: "ERROR") }
                    completion(.failure(self.convertToBioHaazError(error)))
                    return
                }
                guard let data = data else {
                    if config.debug { BioHaazLogger.shared.log("[ERROR] \(method) \(url) No data received", level: "ERROR") }
                    completion(.failure(BioHaazNetworkError.noData))
                    return
                }
                completion(.success(data))
                self.inProgressTasks.removeValue(forKey: key)
            }
            self.inProgressTasks[key] = task
            task.resume()
        }
        // If token is being refreshed, queue the request
        if isRefreshingToken {
            pendingRequests.append(executeRequest)
        } else {
            executeRequest()
        }
    }
    
    // MARK: - Token Refresh Logic
    private func handleTokenRefresh(success: @escaping () -> Void, failure: @escaping () -> Void) {
        guard !isRefreshingToken, let tokenProvider = tokenProvider else {
            // If already refreshing, queue the request
            pendingRequests.append(success)
            return
        }
        isRefreshingToken = true
        tokenProvider.refreshToken { [weak self] refreshed in
            guard let self = self else { return }
            self.isRefreshingToken = false
            if refreshed {
                // Retry all pending requests
                let requests = self.pendingRequests
                self.pendingRequests.removeAll()
                requests.forEach { $0() }
                success()
            } else {
                // Fail all pending requests
                let requests = self.pendingRequests
                self.pendingRequests.removeAll()
                requests.forEach { _ in failure() }
                failure()
            }
        }
    }
    
    // MARK: - File Upload (Multipart/Form-Data)
    /// Uploads a file using multipart/form-data.
    /// - Parameters:
    ///   - url: Endpoint path
    ///   - fileData: Data of the file to upload
    ///   - params: Additional form parameters
    ///   - fileName: Name of the file
    ///   - mimeType: MIME type of the file
    ///   - headers: Optional HTTP headers
    ///   - completion: Completion handler with Result<Data, BioHaazNetworkError>
    public func uploadFile(
        url: String,
        fileData: Data,
        params: [String: Any]? = nil,
        fileName: String = "file",
        mimeType: String = "application/octet-stream",
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, BioHaazNetworkError>) -> Void
    ) {
        guard let config = config else {
            completion(.failure(BioHaazNetworkError.notInitialized))
            return
        }
        guard let requestURL = URL(string: (config.environments[currentEnvironment ?? config.defaultEnvironment] ?? "") + url) else {
            completion(.failure(BioHaazNetworkError.invalidURL))
            return
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let token = tokenProvider?.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Build multipart body
        var body = Data()
        if let params = params {
            for (key, value) in params {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        // Logging
        if config.loggingEnabled {
            print("[BioHaazNetwork] Upload Request: \(request)")
        }
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(self?.convertToBioHaazError(error) ?? BioHaazNetworkError.custom(code: -999, description: error.localizedDescription)))
                return
            }
            guard let data = data else {
                completion(.failure(BioHaazNetworkError.noData))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }

    // MARK: - File Download with Progress
    /// Downloads a file from a remote URL to a local destination, with progress reporting.
    /// - Parameters:
    ///   - from: Remote file URL (relative to base URL)
    ///   - to: Local file URL to save the download
    ///   - progress: Optional progress callback (0.0 to 1.0)
    ///   - completion: Completion handler with Result<URL, BioHaazNetworkError>
    public func downloadFile(
        from url: String,
        to destination: URL,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<URL, BioHaazNetworkError>) -> Void
    ) {
        guard let config = config else {
            completion(.failure(BioHaazNetworkError.notInitialized))
            return
        }
        guard let requestURL = URL(string: (config.environments[currentEnvironment ?? config.defaultEnvironment] ?? "") + url) else {
            completion(.failure(BioHaazNetworkError.invalidURL))
            return
        }
        let request = URLRequest(url: requestURL)
        let task = urlSession.downloadTask(with: request) { [weak self] tempURL, response, error in
            if let error = error {
                completion(.failure(self?.convertToBioHaazError(error) ?? BioHaazNetworkError.custom(code: -999, description: error.localizedDescription)))
                return
            }
            guard let tempURL = tempURL else {
                completion(.failure(BioHaazNetworkError.noData))
                return
            }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
                completion(.success(destination))
            } catch {
                completion(.failure(self?.convertToBioHaazError(error) ?? BioHaazNetworkError.custom(code: -999, description: error.localizedDescription)))
            }
        }
        // Progress handler
        if let progress = progress {
            _ = task.progress.observe(\.fractionCompleted) { prog, _ in
                DispatchQueue.main.async {
                    progress(prog.fractionCompleted)
                }
            }
            // Note: observation will be deallocated after task completes
        }
        task.resume()
    }
    
    // MARK: - Plugin Architecture
    /// Registers a plugin for analytics, hooks, or custom error handling.
    /// - Parameter plugin: The plugin to register.
    public func registerPlugin(_ plugin: BioHaazPlugin) {
        config?.plugins.append(plugin)
    }

    // MARK: - Secure Storage Integration
    private let tokenKey = "BioHaazNetworkToken"
    
    private func storeTokenSecurely(_ token: String) {
        BioHaazKeychain.set(token, forKey: tokenKey)
    }
    
    private func getTokenFromSecureStorage() -> String? {
        switch BioHaazKeychain.get(tokenKey) {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    private func deleteTokenFromSecureStorage() {
        BioHaazKeychain.delete(tokenKey)
    }
    
    // MARK: - Offline Queue Status
    /// Get offline queue status and statistics
    /// - Returns: Dictionary with queue status details
    public func getOfflineQueueStatus() -> [String: Any] {
        let queueStatistics = BioHaazOfflineQueue.shared.getQueueStatistics()
        let queueStatus = checkOfflineQueueStatus()
        
        return [
            "offlineRequestsCount": queueStatistics["totalCount"] ?? 0,
            "queueStatistics": queueStatistics,
            "hasItems": queueStatus.hasItems,
            "manualProcessingAvailable": true
        ]
    }
    
    /// Get offline queue status and statistics
    /// - Returns: Dictionary with queue status details
    /// - Deprecated: Use `getOfflineQueueStatus()` instead
    @available(*, deprecated, message: "Use getOfflineQueueStatus() instead")
    public func getBackgroundProcessingStatus() -> [String: Any] {
        return getOfflineQueueStatus()
    }
    
    // MARK: - Manual Offline Queue Processing
    /// Manually check and process offline queue when app wakes up.
    /// 
    /// Call this method when app is awakened by:
    /// - Push notifications (in `UNUserNotificationCenterDelegate`)
    /// - Location updates (in `CLLocationManagerDelegate`)
    /// - Other background modes
    /// 
    /// - Parameters:
    ///   - force: If `true`, processes queue even if network appears unavailable (default: `false`)
    ///   - completion: Optional completion handler with detailed processing results
    /// 
    /// - Returns: Result containing processed count, failed count, remaining count, and total attempted
    public func processOfflineQueue(
        force: Bool = false,
        completion: ((Result<OfflineQueueProcessingResult, BioHaazNetworkError>) -> Void)? = nil
    ) {
        guard let config = config else {
            completion?(.failure(.notInitialized))
            return
        }
        
        // Prevent multiple simultaneous queue processing
        guard !isProcessingQueue else {
            if config.debug {
                BioHaazLogger.shared.log("[OFFLINE] Queue processing already in progress, skipping", level: "WARNING")
            }
            let currentCount = BioHaazOfflineQueue.shared.getQueueCount()
            completion?(.success(OfflineQueueProcessingResult(
                processedCount: 0,
                failedCount: 0,
                remainingCount: currentCount,
                totalAttempted: 0
            )))
            return
        }
        
        // Check network availability (unless forced)
        if !force && !isNetworkAvailable {
            if config.debug {
                BioHaazLogger.shared.log("[OFFLINE] Network unavailable, skipping queue processing", level: "WARNING")
            }
            let queueCount = BioHaazOfflineQueue.shared.getQueueCount()
            completion?(.failure(.noNetwork))
            return
        }
        
        // Get initial queue count
        let initialQueueCount = BioHaazOfflineQueue.shared.getQueueCount()
        
        guard initialQueueCount > 0 else {
            if config.debug {
                BioHaazLogger.shared.log("[OFFLINE] No offline requests to process", level: "INFO")
            }
            completion?(.success(OfflineQueueProcessingResult(
                processedCount: 0,
                failedCount: 0,
                remainingCount: 0,
                totalAttempted: 0
            )))
            return
        }
        
        isProcessingQueue = true
        
        if config.debug {
            BioHaazLogger.shared.log("[OFFLINE] Starting manual queue processing for \(initialQueueCount) requests", level: "INFO")
        }
        
        // Track processing results using thread-safe counters
        let processedCount = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        processedCount.initialize(to: 0)
        let failedCount = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        failedCount.initialize(to: 0)
        let completedCount = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        completedCount.initialize(to: 0)
        
        let dispatchGroup = DispatchGroup()
        
        // Process the queue
        let result = BioHaazOfflineQueue.shared.processQueue(using: { [weak self] request in
            guard let self = self else { return }
            
            dispatchGroup.enter()
            
            // Execute the queued request
            let task = self.urlSession.dataTask(with: request) { [weak self] data, response, error in
                defer { dispatchGroup.leave() }
                
                guard let self = self, let config = self.config else { return }
                
                completedCount.pointee += 1
                
                if let error = error {
                    failedCount.pointee += 1
                    if config.debug {
                        BioHaazLogger.shared.log("[OFFLINE] Failed to process queued request: \(error.localizedDescription)", level: "ERROR")
                    }
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        processedCount.pointee += 1
                        if config.debug {
                            BioHaazLogger.shared.log("[OFFLINE] Successfully processed queued request: \(httpResponse.statusCode)", level: "SUCCESS")
                        }
                    } else {
                        failedCount.pointee += 1
                        if config.debug {
                            BioHaazLogger.shared.log("[OFFLINE] Request completed with error status: \(httpResponse.statusCode)", level: "WARNING")
                        }
                    }
                } else {
                    failedCount.pointee += 1
                }
            }
            task.resume()
        }, sendNotifications: false)
        
        // Handle immediate errors
        if case .failure(let error) = result {
            processedCount.deallocate()
            failedCount.deallocate()
            completedCount.deallocate()
            isProcessingQueue = false
            if config.debug {
                BioHaazLogger.shared.log("[OFFLINE] Queue processing failed: \(error.localizedDescription)", level: "ERROR")
            }
            completion?(.failure(error))
            return
        }
        
        // Wait for all requests to complete (with timeout)
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self, let config = self.config else {
                processedCount.deallocate()
                failedCount.deallocate()
                completedCount.deallocate()
                return
            }
            
            let finalProcessed = processedCount.pointee
            let finalFailed = failedCount.pointee
            let remainingCount = BioHaazOfflineQueue.shared.getQueueCount()
            let totalAttempted = completedCount.pointee
            
            let result = OfflineQueueProcessingResult(
                processedCount: finalProcessed,
                failedCount: finalFailed,
                remainingCount: remainingCount,
                totalAttempted: totalAttempted
            )
            
            // MARK: - Notification Service (Commented for next version)
            // Send a single combined notification if enabled and there were results
            // if config.offlineNotificationService && (finalProcessed > 0 || finalFailed > 0) {
            //     BioHaazNotificationService.shared.sendOfflineQueueProcessingSummary(
            //         processedCount: finalProcessed,
            //         failedCount: finalFailed,
            //         title: config.notificationTitle,
            //         customBody: finalProcessed > 0 && finalFailed == 0 ? config.notificationBody : nil
            //     )
            // }
            
            if config.debug {
                BioHaazLogger.shared.log("[OFFLINE] Queue processing completed: \(finalProcessed) processed, \(finalFailed) failed, \(remainingCount) remaining", level: finalProcessed > 0 ? "SUCCESS" : "WARNING")
            }
            
            self.isProcessingQueue = false
            completion?(.success(result))
            
            // Cleanup
            processedCount.deallocate()
            failedCount.deallocate()
            completedCount.deallocate()
        }
    }
    
    /// Check offline queue status without processing
    /// - Returns: Tuple with queue count and whether queue has items
    public func checkOfflineQueueStatus() -> (count: Int, hasItems: Bool) {
        let count = BioHaazOfflineQueue.shared.getQueueCount()
        return (count: count, hasItems: count > 0)
    }
    
    /// Clear all items from the offline queue
    /// - Returns: Result indicating success or failure
    public func clearOfflineQueue() -> Result<Void, BioHaazNetworkError> {
        let result = BioHaazOfflineQueue.shared.clear()
        
        if let config = config, config.debug {
            BioHaazLogger.shared.log("[OFFLINE] Queue cleared successfully", level: "INFO")
        }
        
        return result
    }
    
}

// MARK: - Token Provider Protocol
// MARK: - Error Conversion Helper
extension BioHaazNetworkManager {
    /// Safely converts any Error to BioHaazNetworkError
    private func convertToBioHaazError(_ error: Error) -> BioHaazNetworkError {
        // If it's already a BioHaazNetworkError, return as is
        if let bioHaazError = error as? BioHaazNetworkError {
            return bioHaazError
        }
        
        // Handle NSURLError specifically
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return BioHaazNetworkError.noNetwork
            case .timedOut:
                return BioHaazNetworkError.custom(code: -1001, description: "Request timed out")
            case .badURL, .unsupportedURL:
                return BioHaazNetworkError.invalidURL
            case .cannotFindHost, .cannotConnectToHost:
                return BioHaazNetworkError.custom(code: -1003, description: "Cannot connect to server")
            default:
                return BioHaazNetworkError.custom(code: urlError.errorCode, description: urlError.localizedDescription)
            }
        }
        
        // Handle other NSError types
        if let nsError = error as NSError? {
            return BioHaazNetworkError.custom(code: nsError.code, description: "\(nsError.domain): \(nsError.localizedDescription)")
        }
        
        // Fallback for any other error type
        return BioHaazNetworkError.custom(code: -999, description: error.localizedDescription)
    }
}

public protocol BioHaazTokenProvider {
    func getToken() -> String?
    func refreshToken(completion: @escaping (Bool) -> Void)
    func storeToken(_ token: String)
}
