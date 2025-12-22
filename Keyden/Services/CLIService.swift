//
//  CLIService.swift
//  Keyden
//
//  CLI installation and management service
//

import Foundation
import AppKit
import Security

/// Service for managing CLI tool installation
final class CLIService {
    static let shared = CLIService()
    
    private let cliName = "keyden"
    private let installPath = "/usr/local/bin/keyden"
    
    private init() {}
    
    /// Check if CLI is installed and accessible in PATH
    var isInstalled: Bool {
        // Check if file exists at install path
        if FileManager.default.fileExists(atPath: installPath) {
            return true
        }
        
        // Also check if 'keyden' is accessible via PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [cliName]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Get the bundled CLI path inside the app
    var bundledCLIPath: URL? {
        Bundle.main.url(forResource: cliName, withExtension: nil, subdirectory: "CLI")
    }
    
    /// Install CLI to /usr/local/bin with admin privileges
    func installCLI(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sourcePath = bundledCLIPath else {
            completion(.failure(CLIError.cliNotBundled))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Create script content - escape paths properly
                let sourcePathEscaped = sourcePath.path.replacingOccurrences(of: "'", with: "'\\''")
                let installPathEscaped = self.installPath.replacingOccurrences(of: "'", with: "'\\''")
                
                let script = "mkdir -p /usr/local/bin && cp '\(sourcePathEscaped)' '\(installPathEscaped)' && chmod +x '\(installPathEscaped)'"
                
                try self.runWithAdminPrivileges(script: script)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Uninstall CLI from /usr/local/bin
    func uninstallCLI(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let installPathEscaped = self.installPath.replacingOccurrences(of: "'", with: "'\\''")
                let script = "rm -f '\(installPathEscaped)'"
                
                try self.runWithAdminPrivileges(script: script)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Run a shell script with administrator privileges using osascript
    private func runWithAdminPrivileges(script: String) throws {
        // Escape the script for AppleScript string
        let escapedScript = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let appleScript = "do shell script \"\(escapedScript)\" with administrator privileges"
        
        // Use osascript command instead of NSAppleScript for better compatibility
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            
            // Check if user cancelled
            if errorMessage.contains("User canceled") || errorMessage.contains("-128") {
                throw CLIError.userCancelled
            }
            
            throw CLIError.installFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

// MARK: - Errors
enum CLIError: LocalizedError {
    case cliNotBundled
    case installFailed(String)
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .cliNotBundled:
            return "CLI tool not found in app bundle"
        case .installFailed(let message):
            return message
        case .userCancelled:
            return "Installation cancelled"
        }
    }
}
