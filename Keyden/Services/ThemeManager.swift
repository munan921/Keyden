//
//  ThemeManager.swift
//  Keyden
//
//  Theme management with light/dark/system modes
//

import SwiftUI
import AppKit

/// Theme mode options
enum ThemeMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// Theme manager singleton
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
            applyTheme()
        }
    }
    
    @Published var isDark: Bool = false
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "themeMode") ?? "System"
        mode = ThemeMode(rawValue: saved) ?? .system
        updateIsDark()
        
        // Listen for system appearance changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    @objc private func systemAppearanceChanged() {
        DispatchQueue.main.async {
            self.updateIsDark()
        }
    }
    
    private func updateIsDark() {
        switch mode {
        case .system:
            isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case .light:
            isDark = false
        case .dark:
            isDark = true
        }
    }
    
    func applyTheme() {
        updateIsDark()
        
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Modern Theme Colors
struct ModernTheme {
    let isDark: Bool
    
    // Backgrounds
    var background: Color {
        isDark 
            ? Color(red: 0.11, green: 0.11, blue: 0.12)
            : Color(red: 0.98, green: 0.98, blue: 0.99)
    }
    
    var cardBackground: Color {
        isDark
            ? Color(red: 0.16, green: 0.16, blue: 0.18)
            : Color.white
    }
    
    var cardBackgroundHover: Color {
        isDark
            ? Color(red: 0.20, green: 0.20, blue: 0.22)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }
    
    // Accent colors
    var accent: Color {
        Color(red: 0.35, green: 0.55, blue: 0.95)  // Modern blue
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.55, blue: 0.95),
                Color(red: 0.50, green: 0.40, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var success: Color {
        Color(red: 0.30, green: 0.75, blue: 0.55)
    }
    
    var warning: Color {
        Color(red: 0.95, green: 0.65, blue: 0.30)
    }
    
    var danger: Color {
        Color(red: 0.90, green: 0.35, blue: 0.40)
    }
    
    // Text
    var textPrimary: Color {
        isDark ? Color.white : Color(red: 0.12, green: 0.12, blue: 0.14)
    }
    
    var textSecondary: Color {
        isDark ? Color(white: 0.6) : Color(white: 0.45)
    }
    
    var textTertiary: Color {
        isDark ? Color(white: 0.4) : Color(white: 0.65)
    }
    
    // Borders and separators
    var border: Color {
        isDark ? Color(white: 0.2) : Color(white: 0.88)
    }
    
    var separator: Color {
        isDark ? Color(white: 0.15) : Color(white: 0.92)
    }
    
    // Shadows
    var cardShadow: Color {
        isDark ? Color.clear : Color.black.opacity(0.06)
    }
    
    // Input fields
    var inputBackground: Color {
        isDark
            ? Color(red: 0.12, green: 0.12, blue: 0.14)
            : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    // Code display
    var codeBackground: Color {
        isDark
            ? Color(red: 0.14, green: 0.14, blue: 0.16)
            : Color(red: 0.96, green: 0.97, blue: 0.98)
    }
}

// MARK: - Environment Key
struct ThemeKey: EnvironmentKey {
    static var defaultValue: ModernTheme {
        ModernTheme(isDark: NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    }
}

extension EnvironmentValues {
    var theme: ModernTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

