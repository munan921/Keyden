# Keyden

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English

A clean and elegant macOS menu bar TOTP authenticator.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

### Features

- 🔐 **Secure Storage** - Store TOTP secrets securely using macOS Keychain
- 📋 **One-Click Copy** - Click to copy verification codes to clipboard
- 📷 **QR Code Scanning** - Add accounts by scanning QR codes
- ☁️ **Gist Sync** - Sync across multiple devices via GitHub Gist
- 🌍 **Multi-Language** - Supports English and Chinese
- 🎨 **Theme Support** - Follows system light/dark theme

### System Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon (M1/M2/M3) or Intel processor

### Installation

#### Download

Download the latest DMG file from the [Releases](https://github.com/tassel/Keyden/releases) page:

- `Keyden-x.x.x-universal.dmg` - Universal version (recommended, supports both Intel and Apple Silicon)
- `Keyden-x.x.x-arm64.dmg` - Apple Silicon only
- `Keyden-x.x.x-x86_64.dmg` - Intel only

Open the DMG file and drag Keyden to the Applications folder.

#### Build from Source

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

### Usage

1. Launch Keyden, the app icon will appear in the menu bar
2. Click the menu bar icon to open the main interface
3. Click the "+" button to add a new TOTP account
4. Click the verification code to copy it to clipboard

### Build Commands

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

### Project Structure

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

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Acknowledgments

- Thanks to all developers who contribute to the open source community

---

<a name="中文"></a>
## 中文

一个简洁优雅的 macOS 菜单栏 TOTP 双因素认证器。

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

### 功能特性

- 🔐 **安全存储** - 使用 macOS Keychain 安全存储 TOTP 密钥
- 📋 **一键复制** - 点击即可复制验证码到剪贴板
- 📷 **二维码扫描** - 支持扫描二维码添加账户
- ☁️ **Gist 同步** - 通过 GitHub Gist 在多台设备间同步
- 🌍 **多语言** - 支持中文和英文
- 🎨 **主题支持** - 跟随系统明暗主题

### 系统要求

- macOS 12.0 (Monterey) 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel 处理器

### 安装

#### 下载安装

从 [Releases](https://github.com/tassel/Keyden/releases) 页面下载最新版本的 DMG 文件：

- `Keyden-x.x.x-universal.dmg` - 通用版本（推荐，同时支持 Intel 和 Apple Silicon）
- `Keyden-x.x.x-arm64.dmg` - Apple Silicon 专用版本
- `Keyden-x.x.x-x86_64.dmg` - Intel 专用版本

打开 DMG 文件，将 Keyden 拖入「应用程序」文件夹即可。

#### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/tassel/Keyden.git
cd Keyden

# 使用 Xcode 打开项目
open Keyden.xcodeproj

# 或使用命令行构建
make build

# 创建 DMG 安装包
make dmg
```

### 使用方法

1. 启动 Keyden，应用图标会出现在菜单栏
2. 点击菜单栏图标打开主界面
3. 点击「+」按钮添加新的 TOTP 账户
4. 点击验证码即可复制到剪贴板

### 构建命令

```bash
# 构建通用版本（Universal）
make build

# 构建 Intel 版本
make build-intel

# 构建 Apple Silicon 版本
make build-arm

# 创建所有 DMG 安装包
make dmg

# 仅创建通用版本 DMG
make dmg-universal

# 仅创建 Intel 版本 DMG
make dmg-intel

# 仅创建 Apple Silicon 版本 DMG
make dmg-arm

# 清理构建产物
make clean
```

### 项目结构

```
Keyden/
├── App/                    # 应用入口和控制器
│   ├── AppDelegate.swift
│   └── MenuBarController.swift
├── Models/                 # 数据模型
│   └── Token.swift
├── Views/                  # SwiftUI 视图
│   ├── AddTokenView.swift
│   ├── ManagementView.swift
│   ├── MenuBarContentView.swift
│   └── SettingsView.swift
├── Services/               # 服务层
│   ├── GistSyncService.swift
│   ├── KeychainService.swift
│   ├── QRCodeService.swift
│   ├── ThemeManager.swift
│   ├── TOTPService.swift
│   └── VaultService.swift
└── Localization/           # 本地化资源
    ├── en.lproj/
    └── zh-Hans.lproj/
```

### 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

### 致谢

- 感谢所有为开源社区做出贡献的开发者
