//
//  main.swift
//  KeydenCLI
//
//  Command-line interface for Keyden TOTP
//

import Foundation
import CryptoKit

// MARK: - TOTP Algorithm
enum CLITOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

// MARK: - Token Model
struct CLIToken: Codable {
    var id: UUID
    var issuer: String
    var account: String
    var label: String
    var secret: String
    var digits: Int
    var period: Int
    var algorithm: CLITOTPAlgorithm
    var sortOrder: Int
    var isPinned: Bool
    var updatedAt: Date
    
    var displayName: String {
        if !label.isEmpty { return label }
        if !issuer.isEmpty && !account.isEmpty { return "\(issuer) (\(account))" }
        if !issuer.isEmpty { return issuer }
        if !account.isEmpty { return account }
        return "Unknown"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, issuer, account, label, secret, digits, period, algorithm, sortOrder, isPinned, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        issuer = try container.decode(String.self, forKey: .issuer)
        account = try container.decode(String.self, forKey: .account)
        label = try container.decode(String.self, forKey: .label)
        secret = try container.decode(String.self, forKey: .secret)
        digits = try container.decode(Int.self, forKey: .digits)
        period = try container.decode(Int.self, forKey: .period)
        algorithm = try container.decode(CLITOTPAlgorithm.self, forKey: .algorithm)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

// MARK: - Vault Model
struct CLIVault: Codable {
    var tokens: [CLIToken]
    var vaultVersion: Int
    var schemaVersion: Int
    var updatedAt: Date
}

// MARK: - Encrypted Vault
struct CLIEncryptedVault: Codable {
    let version: Int
    let salt: Data
    let iterations: Int
    let nonce: Data
    let ciphertext: Data
    let tag: Data
}

// MARK: - Keychain Service
class CLIKeychainService {
    private let serviceName = "com.keyden.app"
    
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
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}

// MARK: - TOTP Generator
class CLITOTPGenerator {
    private let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    
    func generateCode(for token: CLIToken) -> String? {
        generateCode(
            secret: token.secret,
            digits: token.digits,
            period: token.period,
            algorithm: token.algorithm
        )
    }
    
    func generateCode(
        secret: String,
        digits: Int = 6,
        period: Int = 30,
        algorithm: CLITOTPAlgorithm = .sha1
    ) -> String? {
        guard let secretData = base32Decode(secret) else { return nil }
        
        let counter = UInt64(Date().timeIntervalSince1970) / UInt64(period)
        var counterBE = counter.bigEndian
        let counterData = Data(bytes: &counterBE, count: 8)
        
        let hmacData: Data
        switch algorithm {
        case .sha1:
            let key = SymmetricKey(data: secretData)
            var hmac = HMAC<Insecure.SHA1>(key: key)
            hmac.update(data: counterData)
            hmacData = Data(hmac.finalize())
        case .sha256:
            let key = SymmetricKey(data: secretData)
            var hmac = HMAC<SHA256>(key: key)
            hmac.update(data: counterData)
            hmacData = Data(hmac.finalize())
        case .sha512:
            let key = SymmetricKey(data: secretData)
            var hmac = HMAC<SHA512>(key: key)
            hmac.update(data: counterData)
            hmacData = Data(hmac.finalize())
        }
        
        let offset = Int(hmacData[hmacData.count - 1] & 0x0f)
        let truncatedHash = hmacData.subdata(in: offset..<(offset + 4))
        
        var code = truncatedHash.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self).bigEndian
        }
        code &= 0x7fffffff
        
        let modulo = UInt32(pow(10.0, Double(digits)))
        code = code % modulo
        
        return String(format: "%0\(digits)d", code)
    }
    
    func remainingSeconds(for period: Int = 30) -> Int {
        let now = Int(Date().timeIntervalSince1970)
        return period - (now % period)
    }
    
    private func base32Decode(_ string: String) -> Data? {
        let cleanedString = string.uppercased().replacingOccurrences(of: " ", with: "")
        var result = Data()
        var buffer: UInt64 = 0
        var bitsLeft = 0
        
        for char in cleanedString {
            guard let index = base32Alphabet.firstIndex(of: char) else {
                if char == "=" { continue }
                return nil
            }
            let value = UInt64(base32Alphabet.distance(from: base32Alphabet.startIndex, to: index))
            buffer = (buffer << 5) | value
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                bitsLeft -= 8
                let byte = UInt8((buffer >> bitsLeft) & 0xff)
                result.append(byte)
            }
        }
        
        return result.isEmpty ? nil : result
    }
}

// MARK: - Vault Service
class CLIVaultService {
    private let keychain = CLIKeychainService()
    private let encryptionKeyName = "encryption_key"
    
    private var vaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Keyden/vault.enc")
    }
    
    func loadVault() throws -> CLIVault {
        guard let keyData = keychain.load(key: encryptionKeyName) else {
            throw CLIError.noEncryptionKey
        }
        let key = SymmetricKey(data: keyData)
        
        guard FileManager.default.fileExists(atPath: vaultFileURL.path) else {
            throw CLIError.noVaultFile
        }
        
        let data = try Data(contentsOf: vaultFileURL)
        let encryptedVault = try JSONDecoder().decode(CLIEncryptedVault.self, from: data)
        
        let nonce = try AES.GCM.Nonce(data: encryptedVault.nonce)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedVault.ciphertext, tag: encryptedVault.tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return try JSONDecoder().decode(CLIVault.self, from: decryptedData)
    }
}

// MARK: - Errors
enum CLIError: Error, LocalizedError {
    case noEncryptionKey
    case noVaultFile
    case tokenNotFound(String)
    case noTokens
    
    var errorDescription: String? {
        switch self {
        case .noEncryptionKey:
            return "Keyden not initialized. Please open Keyden app first."
        case .noVaultFile:
            return "No vault file found. Please add accounts in Keyden app first."
        case .tokenNotFound(let query):
            return "No account found matching '\(query)'"
        case .noTokens:
            return "No accounts configured. Please add accounts in Keyden app first."
        }
    }
}

// MARK: - CLI Commands
struct KeydenCLI {
    let vaultService = CLIVaultService()
    let totpGenerator = CLITOTPGenerator()
    
    func run() {
        let args = Array(CommandLine.arguments.dropFirst())
        
        guard !args.isEmpty else {
            printUsage()
            return
        }
        
        let command = args[0].lowercased()
        
        do {
            switch command {
            case "get", "code":
                guard args.count > 1 else {
                    printError("Missing account name")
                    printUsage()
                    exit(1)
                }
                // Parse issuer:account format or just query
                let queryParts = Array(args.dropFirst())
                try getCode(queryParts: queryParts)
                
            case "list", "ls":
                try listAccounts()
                
            case "search":
                guard args.count > 1 else {
                    printError("Missing search query")
                    exit(1)
                }
                let query = args.dropFirst().joined(separator: " ")
                try searchAccounts(query: query)
                
            case "help", "-h", "--help":
                printUsage()
                
            case "version", "-v", "--version":
                printVersion()
                
            default:
                // Treat as account name for convenience
                try getCode(queryParts: args)
            }
        } catch {
            printError(error.localizedDescription)
            exit(1)
        }
    }
    
    private func getCode(queryParts: [String]) throws {
        let vault = try vaultService.loadVault()
        
        // Parse query: support "issuer:account" or "issuer account" format
        let (issuerQuery, accountQuery) = parseQuery(queryParts)
        
        let matches = findTokens(issuer: issuerQuery, account: accountQuery, in: vault.tokens)
        
        if matches.isEmpty {
            let queryStr = queryParts.joined(separator: " ")
            throw CLIError.tokenNotFound(queryStr)
        }
        
        if matches.count > 1 {
            // Multiple matches - show them and ask user to be more specific
            printError("Multiple accounts found. Please be more specific:")
            for (index, token) in matches.enumerated() {
                let code = totpGenerator.generateCode(for: token) ?? "------"
                FileHandle.standardError.write("  [\(index + 1)] \(token.issuer):\(token.account) -> \(code)\n".data(using: .utf8)!)
            }
            FileHandle.standardError.write("\nUse: keyden get \"issuer:account\" or keyden get issuer account\n".data(using: .utf8)!)
            exit(1)
        }
        
        guard let code = totpGenerator.generateCode(for: matches[0]) else {
            printError("Failed to generate code")
            exit(1)
        }
        
        print(code)
    }
    
    /// Parse query parts into issuer and account
    /// Supports: "GitHub:user@email.com", "GitHub user@email.com", "GitHub"
    private func parseQuery(_ parts: [String]) -> (issuer: String?, account: String?) {
        let joined = parts.joined(separator: " ")
        
        // Check for "issuer:account" format
        if joined.contains(":") {
            let components = joined.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if components.count == 2 {
                return (components[0], components[1])
            }
        }
        
        // Check for "issuer account" format (two separate arguments)
        if parts.count >= 2 {
            // First part is issuer, rest is account
            let issuer = parts[0]
            let account = parts.dropFirst().joined(separator: " ")
            return (issuer, account)
        }
        
        // Single query - could be issuer or account
        return (joined, nil)
    }
    
    /// Find tokens matching issuer and/or account
    private func findTokens(issuer: String?, account: String?, in tokens: [CLIToken]) -> [CLIToken] {
        let issuerLower = issuer?.lowercased()
        let accountLower = account?.lowercased()
        
        // If both issuer and account specified, find exact match
        if let issuerLower = issuerLower, let accountLower = accountLower {
            // Exact match on both
            if let token = tokens.first(where: {
                $0.issuer.lowercased() == issuerLower && $0.account.lowercased() == accountLower
            }) {
                return [token]
            }
            
            // Partial match on both
            let matches = tokens.filter {
                $0.issuer.lowercased().contains(issuerLower) && $0.account.lowercased().contains(accountLower)
            }
            if !matches.isEmpty { return matches }
        }
        
        // Only issuer specified
        if let issuerLower = issuerLower, accountLower == nil {
            // Exact match on issuer
            let exactMatches = tokens.filter { $0.issuer.lowercased() == issuerLower }
            if exactMatches.count == 1 { return exactMatches }
            if exactMatches.count > 1 { return exactMatches } // Return all for user to choose
            
            // Partial match on issuer
            let partialMatches = tokens.filter { $0.issuer.lowercased().contains(issuerLower) }
            if partialMatches.count == 1 { return partialMatches }
            if partialMatches.count > 1 { return partialMatches }
            
            // Try matching display name
            if let token = tokens.first(where: { $0.displayName.lowercased() == issuerLower }) {
                return [token]
            }
            
            // Partial match on display name
            let displayMatches = tokens.filter { $0.displayName.lowercased().contains(issuerLower) }
            if !displayMatches.isEmpty { return displayMatches }
            
            // Try matching account
            let accountMatches = tokens.filter { $0.account.lowercased().contains(issuerLower) }
            if !accountMatches.isEmpty { return accountMatches }
        }
        
        return []
    }
    
    private func listAccounts() throws {
        let vault = try vaultService.loadVault()
        
        guard !vault.tokens.isEmpty else {
            throw CLIError.noTokens
        }
        
        let sorted = vault.tokens.sorted { $0.sortOrder < $1.sortOrder }
        
        for token in sorted {
            let code = totpGenerator.generateCode(for: token) ?? "------"
            let remaining = totpGenerator.remainingSeconds(for: token.period)
            let pin = token.isPinned ? "📌 " : ""
            // Show issuer:account format for clarity
            let name = token.account.isEmpty ? token.issuer : "\(token.issuer):\(token.account)"
            let displayName = name.isEmpty ? token.displayName : name
            print("\(pin)\(displayName) -> \(code) (\(remaining)s)")
        }
    }
    
    private func searchAccounts(query: String) throws {
        let vault = try vaultService.loadVault()
        let lowercaseQuery = query.lowercased()
        
        let matches = vault.tokens.filter {
            $0.displayName.lowercased().contains(lowercaseQuery) ||
            $0.issuer.lowercased().contains(lowercaseQuery) ||
            $0.account.lowercased().contains(lowercaseQuery)
        }
        
        guard !matches.isEmpty else {
            throw CLIError.tokenNotFound(query)
        }
        
        for token in matches {
            let code = totpGenerator.generateCode(for: token) ?? "------"
            let remaining = totpGenerator.remainingSeconds(for: token.period)
            let name = token.account.isEmpty ? token.issuer : "\(token.issuer):\(token.account)"
            let displayName = name.isEmpty ? token.displayName : name
            print("\(displayName) -> \(code) (\(remaining)s)")
        }
    }
    
    private func printUsage() {
        print("""
        Keyden CLI - TOTP Code Generator
        
        USAGE:
            keyden <command> [arguments]
        
        COMMANDS:
            get <name>              Get TOTP code for an account
            get <issuer>:<account>  Get code with specific issuer and account
            get <issuer> <account>  Same as above (space separated)
            list                    List all accounts with current codes
            search <query>          Search accounts by name
            help                    Show this help message
            version                 Show version
        
        EXAMPLES:
            keyden get GitHub                    # If only one GitHub account
            keyden get GitHub:user@example.com   # Specific account
            keyden get GitHub user@example.com   # Same as above
            keyden get "Google:work@company.com" # Use quotes if needed
            keyden GitHub                        # Shorthand for 'get'
            keyden list
            keyden search google
        
        TIPS:
            - Use "issuer:account" format when you have multiple accounts
            - Account matching is case-insensitive
            - Partial matches work (e.g., 'git' matches 'GitHub')
            - If multiple matches found, all will be shown
        """)
    }
    
    private func printVersion() {
        print("Keyden CLI v1.0.0")
    }
    
    private func printError(_ message: String) {
        FileHandle.standardError.write("Error: \(message)\n".data(using: .utf8)!)
    }
}

// MARK: - Main
let cli = KeydenCLI()
cli.run()
