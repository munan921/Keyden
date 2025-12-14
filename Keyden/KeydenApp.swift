//
//  KeydenApp.swift
//  Keyden
//
//  Menu bar TOTP authenticator for macOS
//

import SwiftUI

@main
struct KeydenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty settings scene - we're a menu bar app
        Settings {
            EmptyView()
        }
    }
}
