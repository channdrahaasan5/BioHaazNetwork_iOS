//
//  BioHaazLogger.swift
//  BioHaazNetwork
//
//  Enhanced logger utility for debug mode with complete API request/response logging.
//

import Foundation

public class BioHaazLogger {
    public static let shared = BioHaazLogger()
    private let sdkName = "BioHaazNetwork"
    private let fileManager = FileManager.default
    private var debugEnabled: Bool = false
    private var logRetentionDays: Int = 7
    
    private var logFileURL: URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "\(sdkName)_\(dateString).log"
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }
    
    private init() {}
    
    public func configure(debug: Bool, retentionDays: Int = 7) {
        self.debugEnabled = debug
        self.logRetentionDays = retentionDays
        if debug {
            enforceRetentionPolicy()
        }
    }
    
    public func log(_ message: String, level: String = "INFO") {
        guard debugEnabled else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(level)] \(message)\n"
        writeToFile(logEntry)
    }
    
    // MARK: - API Request/Response Logging
    
    public func logApiRequest(
        method: String,
        url: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        requestId: String? = nil
    ) {
        guard debugEnabled else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let id = requestId ?? String(UUID().uuidString.prefix(8))
        
        var logMessage = """
        ========================================
        [\(timestamp)] [API_REQUEST] [\(id)]
        ========================================
        Method: \(method)
        URL: \(url)
        """
        
        if let headers = headers, !headers.isEmpty {
            logMessage += "\nHeaders:"
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                logMessage += "\n  \(key): \(value)"
            }
        }
        
        if let body = body {
            let bodyString = String(data: body, encoding: .utf8) ?? "<binary data>"
            logMessage += "\nBody: \(bodyString)"
        } else {
            logMessage += "\nBody: <empty>"
        }
        
        logMessage += "\n========================================\n"
        writeToFile(logMessage)
    }
    
    public func logApiResponse(
        method: String,
        url: String,
        statusCode: Int,
        headers: [String: String]? = nil,
        body: Data? = nil,
        duration: TimeInterval? = nil,
        requestId: String? = nil
    ) {
        guard debugEnabled else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let id = requestId ?? String(UUID().uuidString.prefix(8))
        
        var logMessage = """
        ========================================
        [\(timestamp)] [API_RESPONSE] [\(id)]
        ========================================
        Method: \(method)
        URL: \(url)
        Status Code: \(statusCode)
        """
        
        if let duration = duration {
            logMessage += "\nDuration: \(String(format: "%.3f", duration))s"
        }
        
        if let headers = headers, !headers.isEmpty {
            logMessage += "\nHeaders:"
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                logMessage += "\n  \(key): \(value)"
            }
        }
        
        if let body = body {
            let bodyString = String(data: body, encoding: .utf8) ?? "<binary data>"
            logMessage += "\nBody: \(bodyString)"
        } else {
            logMessage += "\nBody: <empty>"
        }
        
        logMessage += "\n========================================\n"
        writeToFile(logMessage)
    }
    
    public func logApiError(
        method: String,
        url: String,
        error: Error,
        requestId: String? = nil
    ) {
        guard debugEnabled else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let id = requestId ?? String(UUID().uuidString.prefix(8))
        
        let logMessage = """
        ========================================
        [\(timestamp)] [API_ERROR] [\(id)]
        ========================================
        Method: \(method)
        URL: \(url)
        Error: \(error.localizedDescription)
        Error Code: \((error as NSError).code)
        Error Domain: \((error as NSError).domain)
        ========================================
        
        """
        writeToFile(logMessage)
    }
    
    public func logOfflineQueue(
        action: String,
        queueCount: Int,
        priority: String? = nil,
        requestId: String? = nil
    ) {
        guard debugEnabled else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let id = requestId ?? String(UUID().uuidString.prefix(8))
        
        var logMessage = """
        [\(timestamp)] [OFFLINE_QUEUE] [\(id)]
        Action: \(action)
        Queue Count: \(queueCount)
        """
        
        if let priority = priority {
            logMessage += "\nPriority: \(priority)"
        }
        
        logMessage += "\n"
        writeToFile(logMessage)
    }
    
    public func logBackgroundProcessing(
        action: String,
        queueCount: Int,
        success: Bool
    ) {
        guard debugEnabled else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let status = success ? "SUCCESS" : "FAILED"
        
        let logMessage = """
        [\(timestamp)] [BACKGROUND_PROCESSING] [\(status)]
        Action: \(action)
        Queue Count: \(queueCount)
        
        """
        writeToFile(logMessage)
    }
    
    // MARK: - File Management
    
    private func writeToFile(_ content: String) {
        guard let data = content.data(using: .utf8) else { return }
        
        if fileManager.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }
    
    private func enforceRetentionPolicy() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let files = try? fileManager.contentsOfDirectory(at: docs, includingPropertiesForKeys: [.creationDateKey])
        
        guard let logFiles = files?.filter({ $0.lastPathComponent.hasPrefix(sdkName) && $0.pathExtension == "log" }) else { return }
        
        let sortedFiles = logFiles.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        if sortedFiles.count > logRetentionDays {
            let filesToDelete = sortedFiles.dropFirst(logRetentionDays)
            filesToDelete.forEach { try? fileManager.removeItem(at: $0) }
        }
    }
    
    public func getLogFileURL() -> URL {
        return logFileURL
    }
    
    public func getLogFile() -> URL? {
        guard debugEnabled else { return nil }
        return logFileURL
    }
} 