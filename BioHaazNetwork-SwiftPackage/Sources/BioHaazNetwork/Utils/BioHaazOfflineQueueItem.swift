//
//  BioHaazOfflineQueueItem.swift
//  BioHaazNetwork
//
//  Enhanced queue item with metadata for background processing
//

import Foundation

public struct BioHaazOfflineQueueItem: Codable {
    public let id: String
    public let request: URLRequest
    public let timestamp: Date
    public let retryCount: Int
    public let priority: Priority
    public let maxRetries: Int
    
    public enum Priority: Int, Codable, CaseIterable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
    }
    
    public init(
        request: URLRequest,
        priority: Priority = .normal,
        maxRetries: Int = 3
    ) {
        self.id = UUID().uuidString
        self.request = request
        self.timestamp = Date()
        self.retryCount = 0
        self.priority = priority
        self.maxRetries = maxRetries
    }
    
    public func withIncrementedRetry() -> BioHaazOfflineQueueItem {
        return BioHaazOfflineQueueItem(
            id: self.id,
            request: self.request,
            timestamp: self.timestamp,
            retryCount: self.retryCount + 1,
            priority: self.priority,
            maxRetries: self.maxRetries
        )
    }
    
    public init(
        id: String,
        request: URLRequest,
        timestamp: Date,
        retryCount: Int,
        priority: Priority,
        maxRetries: Int
    ) {
        self.id = id
        self.request = request
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.priority = priority
        self.maxRetries = maxRetries
    }
}

// MARK: - URLRequest Codable Extension
extension URLRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case url, httpMethod, allHTTPHeaderFields, httpBody
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        self.init(url: url)
        
        self.httpMethod = try container.decodeIfPresent(String.self, forKey: .httpMethod)
        self.allHTTPHeaderFields = try container.decodeIfPresent([String: String].self, forKey: .allHTTPHeaderFields)
        self.httpBody = try container.decodeIfPresent(Data.self, forKey: .httpBody)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(httpMethod, forKey: .httpMethod)
        try container.encodeIfPresent(allHTTPHeaderFields, forKey: .allHTTPHeaderFields)
        try container.encodeIfPresent(httpBody, forKey: .httpBody)
    }
}






