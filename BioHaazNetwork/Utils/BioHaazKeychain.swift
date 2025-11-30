//
//  BioHaazKeychain.swift
//  BioHaazNetwork
//
//  Utility for secure token storage using Keychain
//

import Foundation
import Security

public class BioHaazKeychain {
    @discardableResult
    public static func set(_ value: String, forKey key: String) -> Result<Void, BioHaazNetworkError> {
        guard let data = value.data(using: .utf8) else { return .failure(.keychainError(reason: "Failed to encode value to data")) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary) // Remove old item if exists
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            return .success(())
        } else {
            return .failure(.keychainError(reason: "Failed to add item to keychain with status: \(status)"))
        }
    }
    
    public static func get(_ key: String) -> Result<String, BioHaazNetworkError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            if let decodedString = String(data: data, encoding: .utf8) {
                return .success(decodedString)
            } else {
                return .failure(.keychainError(reason: "Failed to decode data to string"))
            }
        } else {
            return .failure(.keychainError(reason: "Failed to get item from keychain with status: \(status)"))
        }
    }
    
    @discardableResult
    public static func delete(_ key: String) -> Result<Void, BioHaazNetworkError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            return .success(())
        } else {
            return .failure(.keychainError(reason: "Failed to delete item from keychain with status: \(status)"))
        }
    }
} 