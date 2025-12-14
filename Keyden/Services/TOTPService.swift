//
//  TOTPService.swift
//  Keyden
//
//  TOTP code generation using CryptoKit
//

import Foundation
import CryptoKit

/// Service for generating TOTP codes
final class TOTPService {
    static let shared = TOTPService()
    
    private init() {}
    
    /// Generate TOTP code for a token at current time
    func generateCode(for token: Token) -> String? {
        generateCode(
            secret: token.secret,
            digits: token.digits,
            period: token.period,
            algorithm: token.algorithm,
            time: Date()
        )
    }
    
    /// Generate TOTP code with specific parameters
    func generateCode(
        secret: String,
        digits: Int = 6,
        period: Int = 30,
        algorithm: TOTPAlgorithm = .sha1,
        time: Date = Date()
    ) -> String? {
        guard let secretData = base32Decode(secret) else {
            return nil
        }
        
        let counter = UInt64(time.timeIntervalSince1970) / UInt64(period)
        
        // Convert counter to big-endian bytes
        var counterBE = counter.bigEndian
        let counterData = Data(bytes: &counterBE, count: 8)
        
        // Calculate HMAC based on algorithm
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
        
        // Dynamic truncation
        let offset = Int(hmacData[hmacData.count - 1] & 0x0f)
        let truncatedHash = hmacData.subdata(in: offset..<(offset + 4))
        
        var code = truncatedHash.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self).bigEndian
        }
        code &= 0x7fffffff
        
        // Get the specified number of digits
        let modulo = UInt32(pow(10.0, Double(digits)))
        code = code % modulo
        
        return String(format: "%0\(digits)d", code)
    }
    
    /// Calculate remaining seconds until next code
    func remainingSeconds(for period: Int = 30) -> Int {
        let now = Int(Date().timeIntervalSince1970)
        return period - (now % period)
    }
    
    /// Calculate progress (0.0 to 1.0) for countdown
    func progress(for period: Int = 30) -> Double {
        let remaining = remainingSeconds(for: period)
        return Double(remaining) / Double(period)
    }
    
    // MARK: - Base32 Decoding
    
    private let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    
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
    
    /// Validate Base32 secret
    func isValidBase32(_ string: String) -> Bool {
        let cleaned = string.uppercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "=", with: "")
        return cleaned.allSatisfy { base32Alphabet.contains($0) } && !cleaned.isEmpty
    }
}

