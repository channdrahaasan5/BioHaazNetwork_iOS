//
//  BioHaazRetryPolicy.swift
//  BioHaazNetwork
//
//  Utility for global retry logic with exponential backoff and jitter
//

import Foundation

public struct BioHaazRetryPolicy {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let retryableMethods: Set<String>
    
    public init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 10.0, retryableMethods: Set<String> = ["GET", "PUT"]) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.retryableMethods = retryableMethods
    }
    
    public func shouldRetry(method: String, error: Error?, response: URLResponse?, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        guard retryableMethods.contains(method.uppercased()) else { return false }
        if let urlError = error as? URLError {
            // Retry on network errors/timeouts
            return urlError.code == .timedOut || urlError.code == .cannotFindHost || urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost || urlError.code == .notConnectedToInternet
        }
        if let httpResponse = response as? HTTPURLResponse {
            // Retry on 5xx server errors
            return (500...599).contains(httpResponse.statusCode)
        }
        return false
    }
    
    public func nextDelay(attempt: Int) -> TimeInterval {
        let exp = pow(2.0, Double(attempt)) * baseDelay
        let jitter = Double.random(in: 0...(baseDelay/2))
        return min(exp + jitter, maxDelay)
    }
} 