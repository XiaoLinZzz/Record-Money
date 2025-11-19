//
//  ColorExtension.swift
//  AutoBookkeeping
//
//  SwiftUI Color 扩展 - 支持 Hex 颜色
//

import SwiftUI

extension Color {

    // MARK: - Hex Color Initialization

    /// 从十六进制字符串创建 Color
    /// - Parameter hex: 十六进制颜色字符串（支持 "#RRGGBB" 或 "RRGGBB" 格式）
    /// - Returns: Color 对象，解析失败返回 nil
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        guard hexSanitized.count == 6 else {
            return nil
        }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    // MARK: - Hex String Conversion

    /// 将 Color 转换为十六进制字符串
    /// - Parameter includeHash: 是否包含 # 前缀，默认 true
    /// - Returns: 十六进制颜色字符串
    func toHex(includeHash: Bool = true) -> String {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return includeHash ? "#000000" : "000000"
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        let hex = String(
            format: "%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)
        )

        return includeHash ? "#\(hex)" : hex
    }

    // MARK: - Predefined Colors

    /// 预定义的常用颜色（hex 格式）
    static let hexColors: [String: Color] = [
        // 暖色系
        "red": Color(hex: "#FF6B6B")!,
        "orange": Color(hex: "#FFA94D")!,
        "yellow": Color(hex: "#FFE66D")!,
        "pink": Color(hex: "#FF8B94")!,

        // 冷色系
        "green": Color(hex: "#A8E6CF")!,
        "cyan": Color(hex: "#4ECDC4")!,
        "blue": Color(hex: "#95E1D3")!,
        "purple": Color(hex: "#C7CEEA")!,

        // 中性色
        "gray": Color(hex: "#95A5A6")!,
        "brown": Color(hex: "#B4A7D6")!,
        "teal": Color(hex: "#76D7C4")!,
        "lavender": Color(hex: "#D4A5A5")!
    ]

    // MARK: - Brightness & Contrast

    /// 判断颜色是否为深色
    var isDark: Bool {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return false
        }

        let r = components[0]
        let g = components[1]
        let b = components[2]

        // 使用相对亮度公式
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness < 0.5
    }

    /// 返回适合该背景色的文本颜色（黑色或白色）
    var contrastingTextColor: Color {
        isDark ? .white : .black
    }
}

// MARK: - UIColor Bridge

extension UIColor {

    /// 从十六进制字符串创建 UIColor
    /// - Parameter hex: 十六进制颜色字符串
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb),
              hexSanitized.count == 6 else {
            return nil
        }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
