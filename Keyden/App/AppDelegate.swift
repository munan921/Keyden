//
//  AppDelegate.swift
//  Keyden
//
//  App delegate for menu bar app lifecycle
//

import SwiftUI
import AppKit

/// App delegate handling menu bar setup and app lifecycle
final class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    static var shared: AppDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        menuBarController = MenuBarController()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Lock vault on quit
        VaultService.shared.lock()
    }
}

