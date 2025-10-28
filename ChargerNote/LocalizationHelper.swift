//
//  LocalizationHelper.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/28.
//

import Foundation

extension String {
    /// 本地化字符串
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 本地化字符串（带参数）
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

/// 本地化辅助函数
func L(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

/// 本地化辅助函数（带参数）
func L(_ key: String, _ arguments: CVarArg...) -> String {
    return String(format: NSLocalizedString(key, comment: ""), arguments: arguments)
}

