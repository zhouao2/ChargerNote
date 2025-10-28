//
//  Item.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import Foundation
import SwiftData

@Model
final class ChargingRecord {
    var id: UUID
    var location: String
    var amount: Double
    var electricityAmount: Double
    var serviceFee: Double
    var totalAmount: Double
    var chargingTime: Date
    var parkingFee: Double
    var notes: String
    var stationType: String // 充电站类型：特斯拉、小鹏、蔚来、国家电网等
    var recordType: String // 记录类型：充电、换电、维修
    var points: Double // 积分（使用的积分数量，如232极分）
    var discountAmount: Double // 优惠金额
    var extremeEnergyKwh: Double // 极能抵扣的度数（如29.797度）
    
    init(location: String, amount: Double, electricityAmount: Double, serviceFee: Double, totalAmount: Double, chargingTime: Date, parkingFee: Double = 0, notes: String = "", stationType: String, recordType: String = "充电", points: Double = 0, discountAmount: Double = 0, extremeEnergyKwh: Double = 0) {
        self.id = UUID()
        self.location = location
        self.amount = amount
        self.electricityAmount = electricityAmount
        self.serviceFee = serviceFee
        self.totalAmount = totalAmount
        self.chargingTime = chargingTime
        self.parkingFee = parkingFee
        self.notes = notes
        self.stationType = stationType
        self.recordType = recordType
        self.points = points
        self.discountAmount = discountAmount
        self.extremeEnergyKwh = extremeEnergyKwh
    }
}

// 充电站分类模型
@Model
final class ChargingStationCategory {
    var id: UUID
    var name: String
    var color: String // 存储颜色的十六进制值
    var icon: String
    var createdAt: Date
    var sortOrder: Int // 排序顺序
    
    init(name: String, color: String, icon: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}

// 用户设置模型
@Model
final class UserSettings {
    var id: UUID
    var currencyCode: String // "CNY", "USD", "EUR"
    var currencySymbol: String // "¥", "$", "€"
    var currencyName: String // "人民币 (¥)", "美元 ($)", "欧元 (€)"
    var language: String // "zh-Hans", "en"
    
    init(currencyCode: String = "CNY", currencySymbol: String = "¥", currencyName: String = "人民币 (¥)", language: String = "zh-Hans") {
        self.id = UUID()
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.currencyName = currencyName
        self.language = language
    }
}

// 保持原有的Item类以兼容现有代码
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
