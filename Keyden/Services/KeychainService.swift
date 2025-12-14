//
//  KeychainService.swift
//  Keyden
//
//  Secure storage using macOS Keychain
//

import Foundation
import Security

/// Service for secure Keychain storage
final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.keyden.app"
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    /// Save data to Keychain
    func save(key: String, data: Data) -> Bool {
        // Delete existing item first
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Load data from Keychain
    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    /// Delete item from Keychain
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods
    
    /// Save string to Keychain
    func saveString(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    /// Load string from Keychain
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Specific Keys
    
    enum Keys {
        static let githubToken = "github_token"
        static let gistId = "gist_id"
        static let encryptionKey = "encryption_key"
    }
    
    // GitHub Token
    var githubToken: String? {
        get { loadString(key: Keys.githubToken) }
        set {
            if let value = newValue {
                _ = saveString(key: Keys.githubToken, value: value)
            } else {
                delete(key: Keys.githubToken)
            }
        }
    }
    
    // Gist ID
    var gistId: String? {
        get { loadString(key: Keys.gistId) }
        set {
            if let value = newValue {
                _ = saveString(key: Keys.gistId, value: value)
            } else {
                delete(key: Keys.gistId)
            }
        }
    }
}

