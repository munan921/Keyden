//
//  QRCodeService.swift
//  Keyden
//
//  QR Code scanning using Vision framework
//

import Foundation
import Vision
import AppKit

/// Result of QR code scanning
enum QRScanResult {
    case success([OTPAuthURL])
    case noQRCode
    case noOTPAuth
    case error(Error)
}

/// Service for QR code detection and parsing
final class QRCodeService {
    static let shared = QRCodeService()
    
    private init() {}
    
    // MARK: - Clipboard Scanning
    
    /// Scan QR code from clipboard
    func scanClipboard() -> QRScanResult {
        let pasteboard = NSPasteboard.general
        
        // Check for image in clipboard
        if let image = NSImage(pasteboard: pasteboard) {
            return scanImage(image)
        }
        
        // Check for text containing otpauth://
        if let string = pasteboard.string(forType: .string) {
            return parseOTPAuthFromText(string)
        }
        
        return .noQRCode
    }
    
    /// Parse otpauth:// URLs from text
    private func parseOTPAuthFromText(_ text: String) -> QRScanResult {
        // Find all otpauth:// URLs in the text
        let pattern = "otpauth://[^\\s]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return .noOTPAuth
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        var otpAuthURLs: [OTPAuthURL] = []
        
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let urlString = String(text[range])
            if let otpAuth = OTPAuthURL.parse(urlString) {
                otpAuthURLs.append(otpAuth)
            }
        }
        
        if otpAuthURLs.isEmpty {
            return .noOTPAuth
        }
        
        return .success(otpAuthURLs)
    }
    
    // MARK: - Image Scanning
    
    /// Scan QR code from NSImage
    func scanImage(_ image: NSImage) -> QRScanResult {
        print("[QRCodeService] 转换 NSImage 到 CGImage...")
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("[QRCodeService] NSImage 转换失败")
            
            // Try alternative method: get CGImage from representations
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let altCGImage = bitmap.cgImage {
                print("[QRCodeService] 使用备用方法成功获取 CGImage")
                return scanCGImage(altCGImage)
            }
            
            print("[QRCodeService] 备用方法也失败了")
            return .error(QRScanError.invalidImage)
        }
        
        print("[QRCodeService] CGImage 转换成功")
        return scanCGImage(cgImage)
    }
    
    /// Scan QR code from file URL
    func scanImageFile(at url: URL) -> QRScanResult {
        print("[QRCodeService] 尝试加载图片: \(url.path)")
        
        guard let image = NSImage(contentsOf: url) else {
            print("[QRCodeService] 无法加载图片文件")
            return .error(QRScanError.fileNotFound)
        }
        
        print("[QRCodeService] 图片加载成功，尺寸: \(image.size)")
        return scanImage(image)
    }
    
    /// Scan QR code from CGImage using Vision
    private func scanCGImage(_ cgImage: CGImage) -> QRScanResult {
        print("[QRCodeService] 开始扫描 CGImage，尺寸: \(cgImage.width)x\(cgImage.height)")
        
        var detectedBarcodes: [VNBarcodeObservation] = []
        var scanError: Error?
        
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                print("[QRCodeService] Vision 请求错误: \(error.localizedDescription)")
                scanError = error
                return
            }
            
            detectedBarcodes = request.results as? [VNBarcodeObservation] ?? []
            print("[QRCodeService] Vision 检测到 \(detectedBarcodes.count) 个条码")
        }
        
        // Filter for QR codes only
        request.symbologies = [.qr]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("[QRCodeService] Vision 执行失败: \(error.localizedDescription)")
            return .error(error)
        }
        
        if let error = scanError {
            return .error(error)
        }
        
        // Extract otpauth:// URLs from detected QR codes
        var otpAuthURLs: [OTPAuthURL] = []
        
        for barcode in detectedBarcodes {
            print("[QRCodeService] 条码类型: \(barcode.symbology.rawValue)")
            guard let payload = barcode.payloadStringValue else {
                print("[QRCodeService] 条码无内容")
                continue
            }
            
            print("[QRCodeService] 条码内容: \(payload.prefix(100))...")
            
            if let otpAuth = OTPAuthURL.parse(payload) {
                print("[QRCodeService] 解析成功: issuer=\(otpAuth.issuer), account=\(otpAuth.account)")
                otpAuthURLs.append(otpAuth)
            } else {
                print("[QRCodeService] 不是有效的 otpauth:// URL")
            }
        }
        
        if detectedBarcodes.isEmpty {
            print("[QRCodeService] 未检测到任何二维码")
            return .noQRCode
        }
        
        if otpAuthURLs.isEmpty {
            print("[QRCodeService] 检测到二维码但不是 OTP 格式")
            return .noOTPAuth
        }
        
        return .success(otpAuthURLs)
    }
    
    // MARK: - File Picker
    
    /// Show file picker and scan selected image
    func pickAndScanImage() async -> QRScanResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.allowedContentTypes = [.png, .jpeg, .heic, .webP, .tiff, .gif]
                panel.message = "Select an image containing a 2FA QR code"
                panel.prompt = "Scan"
                
                panel.begin { response in
                    guard response == .OK, let url = panel.url else {
                        continuation.resume(returning: .noQRCode)
                        return
                    }
                    
                    let result = self.scanImageFile(at: url)
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

// MARK: - Errors

enum QRScanError: LocalizedError {
    case invalidImage
    case fileNotFound
    case scanFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .fileNotFound:
            return "Image file not found"
        case .scanFailed:
            return "QR code scan failed"
        }
    }
}

