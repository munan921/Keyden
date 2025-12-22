//
//  MenuBarController.swift
//  Keyden
//
//  Menu bar management using NSStatusItem with borderless panel (no arrow)
//

import SwiftUI
import AppKit

/// Notification to show the panel
extension Notification.Name {
    static let showMenuBarPanel = Notification.Name("showMenuBarPanel")
    static let showCLIInstallPrompt = Notification.Name("showCLIInstallPrompt")
}

/// Custom panel that can become key window to accept keyboard input
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Controller for the menu bar status item
final class MenuBarController: ObservableObject {
    static var shared: MenuBarController?
    
    private var statusItem: NSStatusItem?
    private var panel: KeyablePanel?
    private var eventMonitor: Any?
    
    @Published var isPopoverShown: Bool = false
    
    private let panelWidth: CGFloat = 340
    private let panelHeight: CGFloat = 520
    
    init() {
        MenuBarController.shared = self
        setupStatusItem()
        
        // Listen for show panel notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowPanelNotification),
            name: .showMenuBarPanel,
            object: nil
        )
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "key.fill", accessibilityDescription: "Keyden")
            button.action = #selector(togglePanel)
            button.target = self
        }
        
        setupPanel()
        
        // Monitor for clicks outside the panel
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            
            // Check if click is outside the panel and not on a system dialog
            if event.window != panel && event.window?.className != "NSOpenPanel" {
                self.hidePanel()
            }
        }
    }
    
    private func setupPanel() {
        // Create borderless panel that can accept keyboard input
        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel?.isFloatingPanel = true
        panel?.level = .popUpMenu
        panel?.collectionBehavior = [.transient, .ignoresCycle]
        panel?.isOpaque = false
        panel?.backgroundColor = .clear
        panel?.hasShadow = true
        panel?.becomesKeyOnlyIfNeeded = false  // Allow becoming key for text input
        
        // Create hosting view with rounded corners
        let hostingView = NSHostingView(rootView: 
            MenuBarContentView()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        
        panel?.contentView = hostingView
    }
    
    @objc private func togglePanel() {
        if let panel = panel {
            if panel.isVisible {
                hidePanel()
            } else {
                showPanel()
            }
        }
    }
    
    @objc private func handleShowPanelNotification() {
        showPanel()
    }
    
    func showPanel() {
        guard let panel = panel, let button = statusItem?.button else { return }
        
        // Calculate position below the menu bar button
        let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        
        // Position panel directly below the button, centered
        let panelX = buttonRect.midX - (panelWidth / 2)
        let panelY = buttonRect.minY - panelHeight - 4  // 4px gap
        
        panel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
        panel.makeKeyAndOrderFront(nil)
        
        isPopoverShown = true
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hidePanel() {
        panel?.orderOut(nil)
        isPopoverShown = false
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
