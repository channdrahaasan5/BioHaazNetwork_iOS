//
//  BioHaazNetworkError.swift
//  BioHaazNetwork
//
//  Centralized error type for all SDK errors, with standardized codes and descriptions.
//

import Foundation

/// Central error type for BioHaazNetwork SDK.
public enum BioHaazNetworkError: Error, LocalizedError, Equatable {
    // MARK: - Error Cases
    case notInitialized
    case invalidURL
    case noNetwork
    case noData
    case tokenRefreshFailed
    case decodingFailed(reason: String)
    case missingRequiredField(field: String)
    case sslPinningFailed(reason: String?)
    case keychainError(reason: String)
    case offlineQueueError(reason: String)
    case custom(code: Int, description: String)

    // MARK: - Error Domain & Codes
    public static let domain = "BioHaazNetwork"
    
    public var code: Int {
        switch self {
        case .notInitialized: return -1
        case .invalidURL: return -2
        case .noNetwork: return -1009
        case .noData: return -3
        case .tokenRefreshFailed: return -4
        case .decodingFailed: return -10
        case .missingRequiredField: return -11
        case .sslPinningFailed: return -20
        case .keychainError: return -30
        case .offlineQueueError: return -40
        case .custom(let code, _): return code
        }
    }

    // MARK: - LocalizedError
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "BioHaazNetwork SDK is not initialized. Call initialize(with:) before making requests."
        case .invalidURL:
            return "Invalid URL or configuration. Check your endpoint and environment settings."
        case .noNetwork:
            return "No network connection. Request was queued or could not be sent."
        case .noData:
            return "No data received from server."
        case .tokenRefreshFailed:
            return "Token refresh failed. Please check your authentication setup."
        case .decodingFailed(let reason):
            return "Decoding failed: \(reason)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .sslPinningFailed(let reason):
            return "SSL pinning failed. \(reason ?? "")"
        case .keychainError(let reason):
            return "Keychain error: \(reason)"
        case .offlineQueueError(let reason):
            return "Offline queue error: \(reason)"
        case .custom(_, let description):
            return description
        }
    }

    /// Returns a userInfo dictionary suitable for NSError bridging.
    public var userInfo: [String: Any] {
        [NSLocalizedDescriptionKey: errorDescription ?? "Unknown error"]
    }

    /// Returns an NSError representation of this error.
    public var asNSError: NSError {
        NSError(domain: Self.domain, code: code, userInfo: userInfo)
    }
}

// MARK: - Documentation
/**
 Error Codes:
 - -1: Not initialized
 - -2: Invalid URL/config
 - -3: No data
 - -4: Token refresh failed
 - -10: Decoding failed
 - -11: Missing required field
 - -20: SSL pinning failed
 - -30: Keychain error
 - -40: Offline queue error
 - -1009: No network
 - custom: Custom error

 All errors surfaced by the SDK should use this type for consistency and clarity.
*/ 