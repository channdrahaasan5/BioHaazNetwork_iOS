//
//  BioHaazMockProvider.swift
//  BioHaazNetwork
//
//  Provides mock responses for API endpoints in mock mode
//

import Foundation

public class BioHaazMockProvider {
    public static let shared = BioHaazMockProvider()
    private var mockResponses: [String: Data] = [:]
    private let queue = DispatchQueue(label: "BioHaazMockProviderQueue", attributes: .concurrent)
    
    private init() {}
    
    /// Registers a mock response for a given HTTP method and URL path.
    /// - Parameters:
    ///   - method: HTTP method (e.g., "GET", "POST")
    ///   - url: Endpoint path (e.g., "/users")
    ///   - response: The mock response data to return
    public func registerMock(method: String, url: String, response: Data) {
        let key = makeKey(method: method, url: url)
        queue.async(flags: .barrier) {
            self.mockResponses[key] = response
        }
    }
    
    /// Retrieves a registered mock response for a given HTTP method and URL path.
    /// - Parameters:
    ///   - method: HTTP method (e.g., "GET", "POST")
    ///   - url: Endpoint path (e.g., "/users")
    /// - Returns: The mock response data if registered, else nil
    public func getMock(method: String, url: String) -> Data? {
        let key = makeKey(method: method, url: url)
        var data: Data?
        queue.sync {
            data = self.mockResponses[key]
        }
        return data
    }
    
    /// Removes a registered mock response for a given HTTP method and URL path.
    public func removeMock(method: String, url: String) {
        let key = makeKey(method: method, url: url)
        queue.async(flags: .barrier) {
            self.mockResponses.removeValue(forKey: key)
        }
    }
    
    /// Clears all registered mock responses.
    public func clearAllMocks() {
        queue.async(flags: .barrier) {
            self.mockResponses.removeAll()
        }
    }
    
    private func makeKey(method: String, url: String) -> String {
        return "\(method.uppercased())|\(url)"
    }
} 