//
//  DataBackupManager.swift
//  ChargerNote
//
//  自动备份管理器
//  负责本地自动备份、iCloud 手动备份，并预留 CloudKit 升级接口
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - 数据同步协议（为 CloudKit 预留）
protocol DataSyncProtocol {
    func backup() async throws
    func restore() async throws
    func getLastBackupDate() -> Date?
}

// MARK: - 备份管理器
class DataBackupManager: ObservableObject {
    
    static let shared = DataBackupManager()
    
    @Published var lastAutoBackupDate: Date?
    @Published var lastManualBackupDate: Date?
    @Published var isBackingUp = false
    
    private let backupDirectory: URL
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private let lastAutoBackupKey = "LastAutoBackupDate"
    private let lastManualBackupKey = "LastManualBackupDate"
    
    private init() {
        // 创建备份目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        backupDirectory = documentsPath.appendingPathComponent("ChargerNoteBackups")
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        // 读取最后备份时间
        if let lastAutoDate = userDefaults.object(forKey: lastAutoBackupKey) as? Date {
            lastAutoBackupDate = lastAutoDate
        }
        if let lastManualDate = userDefaults.object(forKey: lastManualBackupKey) as? Date {
            lastManualBackupDate = lastManualDate
        }
    }
    
    // MARK: - 自动本地备份
    
    /// 执行自动备份
    func performAutoBackup(records: [ChargingRecord], categories: [ChargingStationCategory]) async throws {
        await MainActor.run {
            guard !isBackingUp else { return }
            isBackingUp = true
        }
        
        defer {
            Task { @MainActor in
                isBackingUp = false
            }
        }
        
        print("📦 开始自动本地备份...")
        
        // 准备备份数据
        let backupData = prepareBackupData(records: records, categories: categories)
        
        // 保存到最新备份文件
        let latestBackupURL = backupDirectory.appendingPathComponent("auto_backup_latest.json")
        try saveBackupData(backupData, to: latestBackupURL)
        
        // 保存到日期备份文件（用于历史记录）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        let dateBackupURL = backupDirectory.appendingPathComponent("auto_backup_\(dateString).json")
        try saveBackupData(backupData, to: dateBackupURL)
        
        // 清理旧备份（保留最近 7 天）
        cleanOldBackups()
        
        // 更新最后备份时间
        await MainActor.run {
            lastAutoBackupDate = Date()
            userDefaults.set(lastAutoBackupDate, forKey: lastAutoBackupKey)
        }
        
        print("✅ 自动备份完成")
    }
    
    /// 从本地恢复最新备份
    func restoreFromLocalBackup(modelContext: ModelContext) async throws {
        print("📥 开始从本地恢复备份...")
        
        let latestBackupURL = backupDirectory.appendingPathComponent("auto_backup_latest.json")
        
        guard FileManager.default.fileExists(atPath: latestBackupURL.path) else {
            print("⚠️ 未找到本地备份文件")
            return
        }
        
        let data = try Data(contentsOf: latestBackupURL)
        let backupData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        
        guard let backupData = backupData else {
            throw NSError(domain: "BackupError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的备份文件"])
        }
        
        // 恢复记录
        if let recordsData = backupData["records"] as? [[String: Any]] {
            for recordData in recordsData {
                let record = ChargingRecord(
                    location: recordData["location"] as? String ?? "",
                    amount: recordData["amount"] as? Double ?? 0,
                    electricityAmount: recordData["electricityAmount"] as? Double ?? 0,
                    serviceFee: recordData["serviceFee"] as? Double ?? 0,
                    totalAmount: recordData["totalAmount"] as? Double ?? 0,
                    chargingTime: Date(timeIntervalSince1970: recordData["chargingTime"] as? TimeInterval ?? 0),
                    parkingFee: recordData["parkingFee"] as? Double ?? 0,
                    notes: recordData["notes"] as? String ?? "",
                    stationType: recordData["stationType"] as? String ?? "",
                    recordType: recordData["recordType"] as? String ?? "充电",
                    points: recordData["points"] as? Double ?? 0,
                    discountAmount: recordData["discountAmount"] as? Double ?? 0,
                    extremeEnergyKwh: recordData["extremeEnergyKwh"] as? Double ?? 0
                )
                modelContext.insert(record)
            }
        }
        
        // 恢复充电站分类
        if let categoriesData = backupData["categories"] as? [[String: Any]] {
            for categoryData in categoriesData {
                let category = ChargingStationCategory(
                    name: categoryData["name"] as? String ?? "",
                    color: categoryData["color"] as? String ?? "",
                    icon: categoryData["icon"] as? String ?? "",
                    sortOrder: categoryData["sortOrder"] as? Int ?? 0
                )
                modelContext.insert(category)
            }
        }
        
        print("✅ 本地备份恢复完成")
    }
    
    // MARK: - 手动 iCloud 备份时间更新
    
    /// 更新手动备份时间（在 SettingsView 备份成功后调用）
    @MainActor
    func updateManualBackupDate() {
        lastManualBackupDate = Date()
        userDefaults.set(lastManualBackupDate, forKey: lastManualBackupKey)
    }
    
    // MARK: - 辅助方法
    
    private func prepareBackupData(records: [ChargingRecord], categories: [ChargingStationCategory]) -> [String: Any] {
        var backupData: [String: Any] = [:]
        backupData["version"] = "1.0"
        backupData["timestamp"] = Date().timeIntervalSince1970
        
        // 记录数据
        var recordsArray: [[String: Any]] = []
        for record in records {
            var recordDict: [String: Any] = [:]
            recordDict["chargingTime"] = record.chargingTime.timeIntervalSince1970
            recordDict["location"] = record.location
            recordDict["stationType"] = record.stationType
            recordDict["amount"] = String(format: "%.3f", record.amount)
            recordDict["serviceFee"] = String(format: "%.2f", record.serviceFee)
            recordDict["electricityAmount"] = String(format: "%.2f", record.electricityAmount)
            recordDict["totalAmount"] = String(format: "%.2f", record.totalAmount)
            recordDict["parkingFee"] = String(format: "%.2f", record.parkingFee)
            recordDict["discountAmount"] = String(format: "%.3f", record.discountAmount)
            recordDict["points"] = String(format: "%.0f", record.points)
            recordDict["extremeEnergyKwh"] = String(format: "%.3f", record.extremeEnergyKwh)
            recordDict["notes"] = record.notes
            recordDict["recordType"] = record.recordType
            recordsArray.append(recordDict)
        }
        backupData["records"] = recordsArray
        
        // 分类数据
        var categoriesArray: [[String: Any]] = []
        for category in categories {
            var categoryDict: [String: Any] = [:]
            categoryDict["name"] = category.name
            categoryDict["color"] = category.color
            categoryDict["icon"] = category.icon
            categoryDict["sortOrder"] = category.sortOrder
            categoriesArray.append(categoryDict)
        }
        backupData["categories"] = categoriesArray
        
        return backupData
    }
    
    private func saveBackupData(_ data: [String: Any], to url: URL) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        try jsonData.write(to: url)
    }
    
    private func cleanOldBackups() {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            // 只删除日期备份文件，保留 auto_backup_latest.json
            let dateBackupFiles = files.filter { $0.lastPathComponent.hasPrefix("auto_backup_2") }
            
            // 按创建日期排序
            let sortedFiles = dateBackupFiles.sorted { file1, file2 in
                let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
            }
            
            // 保留最近 7 个，删除其余
            if sortedFiles.count > 7 {
                for file in sortedFiles.dropFirst(7) {
                    try fileManager.removeItem(at: file)
                    print("🗑️ 已删除旧备份: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("⚠️ 清理旧备份失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取最后备份时间的描述
    @MainActor
    func getLastBackupDescription() -> String {
        guard let lastDate = lastManualBackupDate ?? lastAutoBackupDate else {
            return L("backup.never")
        }
        
        let formatter = DateFormatter()
        let isChineseLanguage = Locale.current.language.languageCode?.identifier == "zh"
        
        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            formatter.dateFormat = isChineseLanguage ? "今天 HH:mm" : "'Today' HH:mm"
        } else if calendar.isDateInYesterday(lastDate) {
            formatter.dateFormat = isChineseLanguage ? "昨天 HH:mm" : "'Yesterday' HH:mm"
        } else {
            formatter.dateFormat = isChineseLanguage ? "M月d日 HH:mm" : "MMM d HH:mm"
        }
        
        return formatter.string(from: lastDate)
    }
}

// MARK: - CloudKit 同步服务（预留）
/*
 未来付费后可以启用此服务
 
 class CloudKitSyncService: DataSyncProtocol {
     func backup() async throws {
         // 实现 CloudKit 自动备份
     }
     
     func restore() async throws {
         // 实现 CloudKit 自动恢复
     }
     
     func getLastBackupDate() -> Date? {
         // 返回 CloudKit 最后同步时间
     }
     
     func syncData() async throws {
         // 实现跨设备自动同步
     }
 }
 */

