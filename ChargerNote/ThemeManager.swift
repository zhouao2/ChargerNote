//
//  ThemeManager.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/27.
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case light = "浅色"
    case dark = "深色"
    case system = "跟随系统"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
    }
}

// 自适应颜色扩展
extension Color {
    static let adaptiveBackground = Color(UIColor.systemBackground)
    static let adaptiveSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let adaptiveTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    static let adaptiveGroupedBackground = Color(UIColor.systemGroupedBackground)
    static let adaptiveLabel = Color(UIColor.label)
    static let adaptiveSecondaryLabel = Color(UIColor.secondaryLabel)
    static let adaptiveTertiaryLabel = Color(UIColor.tertiaryLabel)
    static let adaptiveSeparator = Color(UIColor.separator)
    
    // 自定义卡片背景色
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white
    }
    
    // 自定义阴影色
    static func cardShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
    }
    
    // 优化的绿色渐变颜色 - 在深色模式下使用黑色背景
    static func adaptiveGreenColors(for colorScheme: ColorScheme) -> [Color] {
        if colorScheme == .dark {
            // 深色模式：黑色背景
            return [
                Color.black,
                Color.black
            ]
        } else {
            // 浅色模式：原有的亮绿色
            return [
                Color(red: 0.2, green: 0.78, blue: 0.35),
                Color(red: 0.19, green: 0.69, blue: 0.31)
            ]
        }
    }
    
    // 优化的绿色描边色
    static func adaptiveGreenBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.65, blue: 0.25) : Color(red: 0.2, green: 0.78, blue: 0.35)
    }
}

