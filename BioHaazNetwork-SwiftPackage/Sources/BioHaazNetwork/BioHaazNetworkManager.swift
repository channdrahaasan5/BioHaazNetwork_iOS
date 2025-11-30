//
//  BioHaazNetworkManager.swift
//  BioHaazNetwork
//
//  Main entry point for the BioHaazNetwork SDK
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Network

// MARK: - Environment Enum
public enum BioHaazEnvironment: String {
    case dev, qa, uat, prod
}

// MARK: - Config Object
public struct BioHaazNetworkConfig {
    public let environments: [BioHaazEnvironment: String]
    public var defaultEnvironment: BioHaazEnvironment
    public var sslPinningEnabled: Bool
    public var pinnedCertificates: [String: String]?
    public var loggingEnabled: Bool
    public var timeout: TimeInterval
    public var mockMode: Bool
    public var plugins: [BioHaazPlugin]
    public var interceptors: [BioHaazInterceptor]
    public var performanceTracker: BioHaazPerformanceTracker?
    public var autoOfflineProcess: Bool
    public var debug: Bool
    public var offlineNotificationService: Bool
    public var notificationTitle: String
    public var notificationBody: String
     
    public init(
        environments: [BioHaazEnvironment: String],
        defaultEnvironment: BioHaazEnvironment = .prod,
        sslPinningEnabled: Bool = false,
        pinnedCertificates: [String: String]? = nil,
        loggingEnabled: Bool = false,
        timeout: TimeInterval = 30,
        mockMode: Bool = false,
        plugins: [BioHaazPlugin] = [],
        interceptors: [BioHaazInterceptor] = [],
        //performanceTracker: BioHaazPerformanceTracker? = nil,
        autoOfflineProcess: Bool = true,
        debug: Bool = false,
        offlineNotificationService: Bool = false,
        notificationTitle: String = "Offline Request Processed",
        notificationBody: String = "Your offline request has been successfully processed"
    ) {
        self.environments = environments
        self.defaultEnvironment = defaultEnvironment
        self.sslPinningEnabled = sslPinningEnabled
        self.pinnedCertificates = pinnedCertificates
        self.loggingEnabled = loggingEnabled
        self.timeout = timeout
        self.mockMode = mockMode
        self.plugins = plugins
        self.interceptors = interceptors
        //self.performanceTracker = performanceTracker
        self.autoOfflineProcess = autoOfflineProcess
        self.debug = debug
        self.offlineNotificationService = offlineNotificationService
        self.notificationTitle = notificationTitle
        self.notificationBody = notificationBody
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
    // private var backgroundProcessor: BioHaazBackgroundProcessor?
    // private var notificationService: BioHaazNotificationService?
    
    private var pathMonitor: NWPathMonitor?
    private var isNetworkAvailable: Bool = true
    
    private var inProgressTasks: [String: URLSessionDataTask] = [:]
    
    private init() {}
    
    /// Initializes the SDK with the provided configuration.
    /// - Parameter config: The configuration object containing all SDK settings.
    public func initialize(with config: BioHaazNetworkConfig) {
        self.config = config
        self.currentEnvironment = config.defaultEnvironment
        
        // Setup enhanced logging
        BioHaazLogger.shared.configure(debug: config.debug, retentionDays: 7)
        
        // Setup SSL pinning, logging, plugins, etc.
        if config.sslPinningEnabled {
            self.sslDelegate = BioHaazSSLDelegate(pinnedCertificates: config.pinnedCertificates)
            let sessionConfig = URLSessionConfiguration.default
            self.urlSession = URLSession(configuration: sessionConfig, delegate: sslDelegate, delegateQueue: nil)
        } else {
            self.urlSession = URLSession.shared
        }
        
        // Setup background processing
        // backgroundProcessor = BioHaazBackgroundProcessor.shared
        // backgroundProcessor?.startNetworkMonitoring()
        // backgroundProcessor?.scheduleBackgroundTask()
        
        // Setup notification service
        if config.offlineNotificationService {
            // notificationService = BioHaazNotificationService.shared
            // notificationService?.setupNotificationCategories()
            // notificationService?.requestNotificationPermission { granted in
            //     if granted {
            //         print("BioHaazNetwork: Notification permission granted")
            //     } else {
            //         print("BioHaazNetwork: Notification permission denied")
            //     }
            // }
        }
        
        // Setup network monitoring for auto offline process
        if config.autoOfflineProcess {
            setupNetworkMonitor()
        }
    }
    
    private func setupNetworkMonitor() {
        pathMonitor = NWPathMonitor()
        let queue = DispatchQueue(label: "BioHaazNetworkPathMonitor")
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.isNetworkAvailable = path.status == .satisfied
            if self.isNetworkAvailable {
                // Process offline queue when network is back
                // _ = BioHaazOfflineQueue.shared.processQueue { request in
                    // self.sendQueuedRequest(request)
                // }
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
        // Mock mode: return mock response if available
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
        // Offline queueing for POST requests
        if config.autoOfflineProcess, !isNetworkAvailable, method.uppercased() == "POST" {
            // _ = BioHaazOfflineQueue.shared.add(request)
            if config.debug { BioHaazLogger.shared.log("[QUEUE] Queued POST \(url) due to no network", level: "QUEUE") }
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
                    completion(.failure(error as! BioHaazNetworkError))
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
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error as! BioHaazNetworkError))
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
        let task = urlSession.downloadTask(with: request) { tempURL, response, error in
            if let error = error {
                completion(.failure(error as! BioHaazNetworkError))
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
                completion(.failure(error as! BioHaazNetworkError))
            }
        }
        // Progress handler
        if let progress = progress {
            _ = task.progress.observe(\ .fractionCompleted) { prog, _ in
                DispatchQueue.main.async {
                    progress(prog.fractionCompleted)
                }
            }
            // Note: observation will be deallocated after task completes
        }
        task.resume()
    }
    
    // MARK: - Advanced Features (Stubs)
    // Token refresh, secure storage, offline queue, duplicate request cancel, mock mode, etc.

    // MARK: - Plugin Architecture
    /// Registers a plugin for analytics, hooks, or custom error handling.
    /// - Parameter plugin: The plugin to register.
    public func registerPlugin(_ plugin: BioHaazPlugin) {
        config?.plugins.append(plugin)
    }
    
    // Usage:
    // class MyAnalyticsPlugin: BioHaazPlugin { ... }
    // BioHaazNetworkManager.shared.registerPlugin(MyAnalyticsPlugin())

    // MARK: - Token Refresh (Stub)
    private func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        // TODO: Implement token refresh logic using tokenProvider
        completion(false)
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
}

// MARK: - Token Provider Protocol
public protocol BioHaazTokenProvider {
    func getToken() -> String?
    func refreshToken(completion: @escaping (Bool) -> Void)
    func storeToken(_ token: String)
}
