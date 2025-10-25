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
    
    init(location: String, amount: Double, electricityAmount: Double, serviceFee: Double, totalAmount: Double, chargingTime: Date, parkingFee: Double = 0, notes: String = "", stationType: String, recordType: String = "充电") {
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
    
    init(name: String, color: String, icon: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
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
