//
//  UpdateService.swift
//  Keyden
//
//  Service for checking GitHub releases for app updates
//

import Foundation
import SwiftUI

/// Service to check for app updates from GitHub releases
class UpdateService: ObservableObject {
    static let shared = UpdateService()
    
    private let releasesURL = "https://api.github.com/repos/tasselx/Keyden/releases/latest"
    private let releasePageURL = "https://github.com/tasselx/Keyden/releases"
    
    @Published var hasUpdate = false
    @Published var latestVersion: String?
    @Published var isChecking = false
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private init() {}
    
    /// Check for updates on app launch
    func checkForUpdatesOnLaunch() {
        Task {
            await checkForUpdates()
        }
    }
    
    /// Check GitHub releases for a newer version
    @MainActor
    func checkForUpdates() async {
        guard !isChecking else { return }
        
        isChecking = true
        defer { isChecking = false }
        
        guard let url = URL(string: releasesURL) else { return }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                return
            }
            
            // Remove 'v' prefix if present
            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            latestVersion = remoteVersion
            
            // Compare versions
            hasUpdate = isVersion(remoteVersion, greaterThan: currentVersion)
        } catch {
            print("Failed to check for updates: \(error)")
        }
    }
    
    /// Open the releases page in browser
    func openReleasesPage() {
        if let url = URL(string: releasePageURL) {
            NSWorkspace.shared.open(url)
        }
        // Close the menu panel
        MenuBarController.shared?.hidePanel()
    }
    
    /// Compare two semantic version strings
    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1Part = i < v1Components.count ? v1Components[i] : 0
            let v2Part = i < v2Components.count ? v2Components[i] : 0
            
            if v1Part > v2Part {
                return true
            } else if v1Part < v2Part {
                return false
            }
        }
        
        return false
    }
}

