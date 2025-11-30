# BioHaazNetwork iOS SDK - Complete Usage Guide (Corrected)

## Table of Contents
1. [Quick Start](#quick-start)
2. [Configuration](#configuration)
3. [API Methods](#api-methods)
4. [Offline Queue Management](#offline-queue-management)
5. [Background Processing](#background-processing)
6. [Enhanced Logging](#enhanced-logging)
7. [Notification System](#notification-system)
8. [Error Handling](#error-handling)
9. [Advanced Features](#advanced-features)
10. [Complete Examples](#complete-examples)

## Quick Start

### 1. Basic Setup

```swift
import BioHaazNetwork

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure the SDK
        let config = BioHaazNetworkConfig(
            environments: [
                .dev: "https://dev.api.example.com",
                .prod: "https://api.example.com"
            ],
            defaultEnvironment: .prod,
            debug: true,
            autoOfflineProcess: true,
            offlineNotificationService: true,
            notificationTitle: "Network Status",
            notificationBody: "Your request has been processed"
        )
        
        // Initialize the SDK
        BioHaazNetworkManager.shared.initialize(with: config)
        
        return true
    }
}
```

### 2. Make Your First API Call

```swift
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUsers()
    }
    
    private func fetchUsers() {
        BioHaazNetworkManager.shared.request(
            method: "GET",
            url: "/users"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("Users: \(data)")
                    // Handle success
                case .failure(let error):
                    print("Error: \(error)")
                    // Handle error
                }
            }
        }
    }
}
```

## Configuration

### Complete Configuration Options

```swift
let config = BioHaazNetworkConfig(
    // Required - Multi-environment support
    environments: [
        .dev: "https://dev.api.example.com",
        .qa: "https://qa.api.example.com",
        .uat: "https://uat.api.example.com",
        .prod: "https://api.example.com"
    ],
    defaultEnvironment: .prod,
    
    // Optional - Security
    sslPinningEnabled: true,
    pinnedCertificates: ["api.example.com": "<SHA256_HASH>"],
    
    // Optional - Debug & Logging
    loggingEnabled: true,
    debug: true,
    
    // Optional - Network Settings
    timeout: 60.0,
    
    // Optional - Testing
    mockMode: false,
    
    // Optional - Extensibility
    plugins: [],
    interceptors: [],
    performanceTracker: nil,
    
    // Optional - Offline Features
    autoOfflineProcess: true,
    offlineNotificationService: true,
    notificationTitle: "Network Status",
    notificationBody: "Your request has been processed",
    enableBackgroundFetch: true  // Background fetch + manual processing work together
)
```

## API Methods

### GET Request

```swift
// Simple GET
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users"
) { result in
    // Handle result
}

// GET with headers
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users",
    headers: [
        "Authorization": "Bearer your_token",
        "Accept": "application/json"
    ]
) { result in
    // Handle result
}

// GET with query parameters
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users",
    headers: nil,
    params: [
        "page": "1",
        "limit": "10",
        "sort": "name"
    ]
) { result in
    // Handle result
}
```

### POST Request

```swift
// POST with JSON body
let userData = [
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30
]

BioHaazNetworkManager.shared.request(
    method: "POST",
    url: "/users",
    headers: ["Content-Type": "application/json"],
    params: userData
) { result in
    switch result {
    case .success(let data):
        print("User created: \(data)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### PUT Request

```swift
let updateData = [
    "name": "Jane Doe",
    "email": "jane@example.com"
]

BioHaazNetworkManager.shared.request(
    method: "PUT",
    url: "/users/123",
    headers: ["Content-Type": "application/json"],
    params: updateData
) { result in
    // Handle result
}
```

### DELETE Request

```swift
BioHaazNetworkManager.shared.request(
    method: "DELETE",
    url: "/users/123",
    headers: ["Authorization": "Bearer your_token"]
) { result in
    switch result {
    case .success:
        print("User deleted successfully")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## File Operations

### File Upload

```swift
// Upload file
BioHaazNetworkManager.shared.uploadFile(
    url: "/upload",
    fileData: imageData,
    fileName: "photo.jpg",
    mimeType: "image/jpeg"
) { result in
    switch result {
    case .success(let data):
        print("File uploaded: \(data)")
    case .failure(let error):
        print("Upload error: \(error)")
    }
}
```

### File Download

```swift
// Download file
let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("downloaded_file.zip")

BioHaazNetworkManager.shared.downloadFile(
    from: "/file.zip",
    to: destinationURL,
    progress: { progress in
        print("Download progress: \(progress * 100)%")
    },
    completion: { result in
        switch result {
        case .success(let fileURL):
            print("File downloaded to: \(fileURL)")
        case .failure(let error):
            print("Download error: \(error)")
        }
    }
)
```

## Manual Offline Queue Processing (Recommended)

### Overview

Manual processing via `processOfflineQueue()` is more reliable than iOS background fetch, which is unpredictable. Call this method when your app wakes up via:
- Push notifications
- Location updates
- Other background modes

### Basic Usage

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
```

### Check Queue Status

```swift
// Check if there are items in queue without processing
let status = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
if status.hasItems {
    print("\(status.count) items waiting to be processed")
}
```

### Integration with Push Notifications

```swift
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Process offline queue when app wakes up from notification
        BioHaazNetworkManager.shared.processOfflineQueue { result in
            switch result {
            case .success(let processingResult):
                print("Processed \(processingResult.processedCount) requests")
            case .failure(let error):
                print("Failed: \(error.localizedDescription)")
            }
        }
        
        completionHandler()
    }
}
```

### Integration with Location Updates

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process offline queue when location updates
        BioHaazNetworkManager.shared.processOfflineQueue { result in
            // Handle result
        }
    }
}
```

### Integration with App Lifecycle

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Process queue when app becomes active
        let status = BioHaazNetworkManager.shared.checkOfflineQueueStatus()
        if status.hasItems {
            BioHaazNetworkManager.shared.processOfflineQueue { result in
                // Handle result
            }
        }
    }
}
```

### Force Processing

```swift
// Force processing even if network appears unavailable
// Useful when network check might be inaccurate
BioHaazNetworkManager.shared.processOfflineQueue(force: true) { result in
    // Handle result
}
```

## Environment Management

### Switch Environments

```swift
// Switch to development environment
BioHaazNetworkManager.shared.setEnvironment(.dev)

// Get current environment
let currentEnv = BioHaazNetworkManager.shared.getCurrentEnvironment()
print("Current environment: \(currentEnv)")

// Get current base URL
let baseURL = BioHaazNetworkManager.shared.getBaseURL()
print("Current base URL: \(baseURL)")
```

## Plugin System

### Create a Custom Plugin

```swift
class MyAnalyticsPlugin: BioHaazPlugin {
    func onRequest(_ request: URLRequest) {
        print("📤 Request: \(request.url?.absoluteString ?? "")")
        // Add analytics tracking
    }
    
    func onResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response: \(httpResponse.statusCode)")
        }
        // Add analytics tracking
    }
}

// Register the plugin
let analyticsPlugin = MyAnalyticsPlugin()
BioHaazNetworkManager.shared.registerPlugin(analyticsPlugin)
```

## Interceptors

### Create a Custom Interceptor

```swift
class AuthInterceptor: BioHaazInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        
        // Add authentication header
        if let token = getAuthToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers
        modifiedRequest.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")
        
        return modifiedRequest
    }
    
    func intercept(_ response: URLResponse?, data: Data?, error: Error?) {
        // Handle response or errors
        if let error = error {
            print("Request failed: \(error)")
        }
    }
    
    private func getAuthToken() -> String? {
        // Return stored auth token
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

// Use in configuration
let config = BioHaazNetworkConfig(
    environments: [...],
    defaultEnvironment: .prod,
    interceptors: [AuthInterceptor()]
)
```

## Mock Mode

### Enable Mock Mode

```swift
let config = BioHaazNetworkConfig(
    environments: [...],
    defaultEnvironment: .prod,
    mockMode: true  // Enable mock mode
)

// Register mock responses
BioHaazMockProvider.shared.registerMock(
    method: "GET",
    url: "/users",
    response: Data("""
    [
        {"id": 1, "name": "John Doe", "email": "john@example.com"},
        {"id": 2, "name": "Jane Smith", "email": "jane@example.com"}
    ]
    """.utf8)
)
```

## Error Handling

### Error Types

```swift
enum BioHaazNetworkError: Error {
    case notInitialized
    case noNetwork
    case invalidURL
    case timeout
    case serverError(Int)
    case decodingError
    case unknown(Error)
}
```

### Error Handling Examples

```swift
BioHaazNetworkManager.shared.request(
    method: "GET",
    url: "/users"
) { result in
    switch result {
    case .success(let data):
        // Handle success
        print("Success: \(data)")
        
    case .failure(let error):
        // Handle different error types
        switch error {
        case .notInitialized:
            print("SDK not initialized")
            
        case .noNetwork:
            print("No network connection available")
            // Show offline message
            
        case .invalidURL:
            print("Invalid URL provided")
            // Show configuration error
            
        case .timeout:
            print("Request timed out")
            // Show timeout message
            
        case .serverError(let statusCode):
            print("Server error with status: \(statusCode)")
            // Handle specific HTTP status codes
            switch statusCode {
            case 401:
                // Handle unauthorized - redirect to login
            case 404:
                // Handle not found
            case 500:
                // Handle server error
            default:
                // Handle other status codes
            }
            
        case .decodingError:
            print("Failed to decode response")
            // Handle JSON parsing error
            
        case .unknown(let underlyingError):
            print("Unknown error: \(underlyingError)")
            // Handle unexpected errors
        }
    }
}
```

## Complete Examples

### Example 1: User Management Service

```swift
class UserService {
    private let baseURL = "https://api.example.com"
    
    // Fetch all users
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        BioHaazNetworkManager.shared.request(
            method: "GET",
            url: "/users"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let users = try JSONDecoder().decode([User].self, from: data)
                        completion(.success(users))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Create new user
    func createUser(_ user: User, completion: @escaping (Result<User, Error>) -> Void) {
        let userData = [
            "name": user.name,
            "email": user.email,
            "age": user.age
        ]
        
        BioHaazNetworkManager.shared.request(
            method: "POST",
            url: "/users",
            headers: ["Content-Type": "application/json"],
            params: userData
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let createdUser = try JSONDecoder().decode(User.self, from: data)
                        completion(.success(createdUser))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Update user
    func updateUser(_ user: User, completion: @escaping (Result<User, Error>) -> Void) {
        let userData = [
            "name": user.name,
            "email": user.email,
            "age": user.age
        ]
        
        BioHaazNetworkManager.shared.request(
            method: "PUT",
            url: "/users/\(user.id)",
            headers: ["Content-Type": "application/json"],
            params: userData
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let updatedUser = try JSONDecoder().decode(User.self, from: data)
                        completion(.success(updatedUser))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Delete user
    func deleteUser(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        BioHaazNetworkManager.shared.request(
            method: "DELETE",
            url: "/users/\(id)"
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

// User model
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let age: Int
}
```

### Example 2: Complete App Integration

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure BioHaazNetwork
        setupBioHaazNetwork()
        
        return true
    }
    
    private func setupBioHaazNetwork() {
        let config = BioHaazNetworkConfig(
            environments: [
                .dev: "https://dev.api.example.com",
                .prod: "https://api.example.com"
            ],
            defaultEnvironment: .prod,
            debug: true,
            autoOfflineProcess: true,
            offlineNotificationService: true,
            notificationTitle: "Sync Status",
            notificationBody: "Your data has been synchronized",
            timeout: 30.0,
            loggingEnabled: true
        )
        
        BioHaazNetworkManager.shared.initialize(with: config)
    }
}

class MainViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private let userService = UserService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
    }
    
    private func setupUI() {
        statusLabel.text = "Ready to sync"
        activityIndicator.isHidden = true
    }
    
    private func loadInitialData() {
        setLoading(true)
        statusLabel.text = "Loading users..."
        
        userService.fetchUsers { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                switch result {
                case .success(let users):
                    self?.statusLabel.text = "✅ Loaded \(users.count) users"
                case .failure(let error):
                    self?.statusLabel.text = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @IBAction func syncButtonTapped(_ sender: UIButton) {
        setLoading(true)
        statusLabel.text = "Syncing data..."
        
        userService.fetchUsers { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                switch result {
                case .success(let users):
                    self?.statusLabel.text = "✅ Synced \(users.count) users"
                case .failure(let error):
                    self?.statusLabel.text = "❌ Sync failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func setLoading(_ isLoading: Bool) {
        activityIndicator.isHidden = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        syncButton.isEnabled = !isLoading
    }
}
```

## Summary

This corrected usage guide shows the actual API methods available in the BioHaazNetwork iOS framework:

- **Main Class**: `BioHaazNetworkManager.shared`
- **Initialization**: `initialize(with: config)`
- **HTTP Methods**: Use `request(method:url:headers:params:completion:)`
- **File Operations**: `uploadFile()` and `downloadFile()`
- **Environment Management**: `setEnvironment()`, `getCurrentEnvironment()`, `getBaseURL()`
- **Plugin System**: `registerPlugin()`
- **Configuration**: `BioHaazNetworkConfig` with environments dictionary

The framework provides a comprehensive networking solution with offline support, background processing, and extensive customization options.
