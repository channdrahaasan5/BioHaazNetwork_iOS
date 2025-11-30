//
//  BioHaazJSONDecoder.swift
//  BioHaazNetwork
//
//  Utility for automatic JSON-to-Model mapping with validation
//

import Foundation

public protocol BioHaazValidatable {
    func validate() throws
}

public enum BioHaazDecodingError: Error, LocalizedError {
    case missingRequiredField(String)
    case decodingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .decodingFailed(let reason):
            return "Decoding failed: \(reason)"
        }
    }
}

public class BioHaazJSONDecoder {
    public static func decode<T: Decodable>(_ data: Data, to type: T.Type, debug: Bool = false) throws -> T {
        let decoder = JSONDecoder()
        do {
            let model = try decoder.decode(T.self, from: data)
            if let validatable = model as? BioHaazValidatable {
                try validatable.validate()
            }
            return model
        } catch {
            if debug {
                BioHaazLogger.shared.log("[DECODING] Failed to decode \(T.self): \(error.localizedDescription)", level: "DECODING")
            }
            throw BioHaazNetworkError.decodingFailed(reason: error.localizedDescription)
        }
    }
} 