# Keyden

[中文文档](README.zh-CN.md)

A clean and elegant macOS menu bar TOTP authenticator.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🔐 **Secure Storage** - Store TOTP secrets securely using macOS Keychain
- 📋 **One-Click Copy** - Click to copy verification codes to clipboard
- 📷 **QR Code Scanning** - Add accounts by scanning QR codes
- ☁️ **Gist Sync** - Optional sync across multiple devices via GitHub Gist
- 💾 **Offline First** - All data stored locally (encrypted), works without internet
- 🌍 **Multi-Language** - Supports English and Chinese
- 🎨 **Theme Support** - Follows system light/dark theme

## System Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon (M1/M2/M3) or Intel processor

## Installation

### Download

Download the latest DMG file from the [Releases](https://github.com/tassel/Keyden/releases) page:

- `Keyden-x.x.x-universal.dmg` - Universal version (recommended, supports both Intel and Apple Silicon)
- `Keyden-x.x.x-arm64.dmg` - Apple Silicon only
- `Keyden-x.x.x-x86_64.dmg` - Intel only

Open the DMG file and drag Keyden to the Applications folder.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/tassel/Keyden.git
cd Keyden

# Open with Xcode
open Keyden.xcodeproj

# Or build via command line
make build

# Create DMG installers
make dmg
```

## Usage

1. Launch Keyden, the app icon will appear in the menu bar
2. Click the menu bar icon to open the main interface
3. Click the "+" button to add a new TOTP account
4. Click the verification code to copy it to clipboard

## Build Commands

```bash
# Build Universal version
make build

# Build Intel version
make build-intel

# Build Apple Silicon version
make build-arm

# Create all DMG installers
make dmg

# Create Universal DMG only
make dmg-universal

# Create Intel DMG only
make dmg-intel

# Create Apple Silicon DMG only
make dmg-arm

# Clean build artifacts
make clean
```

## Project Structure

```
Keyden/
├── App/                    # App entry and controllers
│   ├── AppDelegate.swift
│   └── MenuBarController.swift
├── Models/                 # Data models
│   └── Token.swift
├── Views/                  # SwiftUI views
│   ├── AddTokenView.swift
│   ├── ManagementView.swift
│   ├── MenuBarContentView.swift
│   └── SettingsView.swift
├── Services/               # Service layer
│   ├── GistSyncService.swift
│   ├── KeychainService.swift
│   ├── QRCodeService.swift
│   ├── ThemeManager.swift
│   ├── TOTPService.swift
│   └── VaultService.swift
└── Localization/           # Localization resources
    ├── en.lproj/
    └── zh-Hans.lproj/
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all developers who contribute to the open source community
