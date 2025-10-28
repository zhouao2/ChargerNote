//
//  SettingsView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    @Query private var chargingRecords: [ChargingRecord]
    @Query private var categories: [ChargingStationCategory]
    @Query private var userSettings: [UserSettings]
    @State private var selectedCurrency: Currency = .cny
    @State private var selectedLanguage: Language = .chinese
    @State private var showingAddCategory = false
    @State private var editingCategory: ChargingStationCategory?
    @State private var showingCategoryManagement = false
    
    // 折叠状态
    @State private var isAppearanceExpanded = false
    @State private var isLanguageExpanded = false
    @State private var isCurrencyExpanded = false
    @State private var isStationExpanded = false
    @State private var isDataExpanded = false
    @State private var isDangerExpanded = false
    
    // iCloud 备份状态
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var backupMessage: String?
    
    // CSV 导出状态
    @State private var isExporting = false
    @State private var exportedFileURL: IdentifiableURL?
    
    // iCloud 备份文件URL
    @State private var iCloudBackupURL: IdentifiableURL?
    @State private var showingDocumentPicker = false
    
    // 删除确认弹窗
    @State private var showingDeleteAlert = false
    
    // 语言切换提示
    @State private var showingLanguageAlert = false
    
    enum Currency: String, CaseIterable {
        case cny = "人民币 (¥)"
        case usd = "美元 ($)"
        case eur = "欧元 (€)"
        
        var icon: String {
            switch self {
            case .cny: return "yensign"
            case .usd: return "dollarsign"
            case .eur: return "eurosign"
            }
        }
        
        var symbol: String {
            switch self {
            case .cny: return "¥"
            case .usd: return "$"
            case .eur: return "€"
            }
        }
        
        var code: String {
            switch self {
            case .cny: return "CNY"
            case .usd: return "USD"
            case .eur: return "EUR"
            }
        }
    }
    
    enum Language: String, CaseIterable {
        case chinese = "中文"
        case english = "English"
        
        var icon: String {
            switch self {
            case .chinese: return "character.textbox"
            case .english: return "textformat.abc"
            }
        }
        
        var code: String {
            switch self {
            case .chinese: return "zh-Hans"
            case .english: return "en"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部导航区域
                        VStack(spacing: 0) {
                            // 绿色渐变背景
                            LinearGradient(
                                gradient: Gradient(colors: Color.adaptiveGreenColors(for: colorScheme)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .overlay(
                                VStack(spacing: 16) {
                                    // 标题和用户
                                    HStack {
                                        Text("设置")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.95) : .white)
                                        Spacer()
                                        Image(systemName: "person.circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.95) : .white)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                    
                                    // 用户信息卡片
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.25))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: "person")
                                                .font(.system(size: 20))
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("充电记账用户")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.95) : .white)
                                            
                                            Text("已记录 \(chargingRecords.count) 条充电记录")
                                                .font(.system(size: 14))
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.75) : .white.opacity(0.95))
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.25))
                                    )
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 16)
                                }
                            )
                            
                            // 白色内容区域
                            VStack(spacing: 24) {
                                // 主题设置
                                CollapsibleSettingsSection(title: "外观设置", isExpanded: $isAppearanceExpanded) {
                                    ForEach(AppTheme.allCases, id: \.self) { theme in
                                        SettingsRow(
                                            icon: theme == .light ? "sun.max.fill" : theme == .dark ? "moon.fill" : "circle.lefthalf.filled",
                                            title: theme.rawValue,
                                            hasCheckmark: themeManager.currentTheme == theme,
                                            action: {
                                                themeManager.currentTheme = theme
                                            }
                                        )
                                    }
                                }
                                
                                // 语言设置
                                CollapsibleSettingsSection(title: "语言 / Language", isExpanded: $isLanguageExpanded) {
                                    ForEach(Language.allCases, id: \.self) { language in
                                        SettingsRow(
                                            icon: language.icon,
                                            title: language.rawValue,
                                            hasCheckmark: selectedLanguage == language,
                                            action: {
                                                selectedLanguage = language
                                                updateLanguageSettings(language)
                                            }
                                        )
                                    }
                                }
                                
                                // 货币单位设置
                                CollapsibleSettingsSection(title: "货币单位", isExpanded: $isCurrencyExpanded) {
                                    ForEach(Currency.allCases, id: \.self) { currency in
                                        SettingsRow(
                                            icon: currency.icon,
                                            title: currency.rawValue,
                                            hasCheckmark: selectedCurrency == currency,
                                            action: {
                                                selectedCurrency = currency
                                                updateCurrencySettings(currency)
                                            }
                                        )
                                    }
                                }
                                
                                // 充电站管理
                                CollapsibleSettingsSection(title: "充电站管理", isExpanded: $isStationExpanded) {
                                    SettingsRow(icon: "mappin.and.ellipse", title: "管理充电站", hasArrow: true, action: {
                                        showingCategoryManagement = true
                                    })
                                }
                                
                                // 数据管理
                                CollapsibleSettingsSection(title: "数据管理", isExpanded: $isDataExpanded) {
                                    SettingsRow(
                                        icon: "square.and.arrow.down",
                                        title: isExporting ? "导出中..." : "导出CSV数据",
                                        hasArrow: true,
                                        action: exportCSV
                                    )
                                    SettingsRow(
                                        icon: "icloud.and.arrow.up",
                                        title: isBackingUp ? "备份中..." : "备份到iCloud",
                                        hasArrow: true,
                                        action: backupToiCloud
                                    )
                                    SettingsRow(
                                        icon: "icloud.and.arrow.down",
                                        title: isRestoring ? "恢复中..." : "从iCloud恢复",
                                        hasArrow: true,
                                        action: restoreFromiCloud
                                    )
                                }
                                
                                // 应用信息
                                SettingsSection(title: "应用信息") {
                                    SettingsRow(title: "版本号", value: "1.0.0")
                                    SettingsRow(title: "构建版本", value: "2025.10.25")
                                    SettingsRow(title: "开发者", value: "Zhou Ao")
                                    SettingsRow(
                                        icon: "link",
                                        title: "GitHub",
                                        hasArrow: true,
                                        showSeparator: false,
                                        action: {
                                            if let url = URL(string: "https://github.com/zhouao2/ChargerNote") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    )
                                }
                                
                                // 危险操作
                                CollapsibleSettingsSection(title: "危险操作", isExpanded: $isDangerExpanded) {
                                    SettingsRow(icon: "trash", title: "清除所有数据", titleColor: .red, hasArrow: true, action: {
                                        showingDeleteAlert = true
                                    })
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 100) // 为底部导航留出空间
                        }
                    }
                }
                
                // 提示消息
                if let message = backupMessage {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(message)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView(showingAddCategory: $showingAddCategory, editingCategory: $editingCategory)
        }
        .sheet(item: Binding(
            get: { exportedFileURL },
            set: { _ in exportedFileURL = nil }
        )) { identifiableURL in
            ShareSheet(items: [identifiableURL.url])
        }
        .sheet(item: Binding(
            get: { iCloudBackupURL },
            set: { _ in iCloudBackupURL = nil }
        )) { identifiableURL in
            ShareSheet(items: [identifiableURL.url])
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(onDocumentPicked: { url in
                restoreFromBackupFile(url: url)
            })
        }
        .alert("清除所有数据", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("此操作将永久删除所有充电记录，此操作不可撤销。确定要继续吗？")
        }
        .alert("语言已更改 / Language Changed", isPresented: $showingLanguageAlert) {
            Button("确定 / OK", role: .cancel) { }
        } message: {
            Text("请重启应用以应用新的语言设置\nPlease restart the app to apply the new language settings")
        }
        .onAppear {
            if categories.isEmpty {
                createDefaultCategories()
            }
            
            // 初始化用户设置
            if userSettings.isEmpty {
                let defaultSettings = UserSettings()
                modelContext.insert(defaultSettings)
            }
            
            // 加载当前货币设置
            if let settings = userSettings.first {
                switch settings.currencyCode {
                case "CNY":
                    selectedCurrency = .cny
                case "USD":
                    selectedCurrency = .usd
                case "EUR":
                    selectedCurrency = .eur
                default:
                    selectedCurrency = .cny
                }
                
                // 加载当前语言设置
                switch settings.language {
                case "zh-Hans":
                    selectedLanguage = .chinese
                case "en":
                    selectedLanguage = .english
                default:
                    selectedLanguage = .chinese
                }
            }
        }
    }
    
    private func updateCurrencySettings(_ currency: Currency) {
        if let settings = userSettings.first {
            settings.currencyCode = currency.code
            settings.currencySymbol = currency.symbol
            settings.currencyName = currency.rawValue
        } else {
            let newSettings = UserSettings(
                currencyCode: currency.code,
                currencySymbol: currency.symbol,
                currencyName: currency.rawValue
            )
            modelContext.insert(newSettings)
        }
    }
    
    private func updateLanguageSettings(_ language: Language) {
        if let settings = userSettings.first {
            settings.language = language.code
        } else {
            let newSettings = UserSettings(language: language.code)
            modelContext.insert(newSettings)
        }
        
        // 更新系统语言偏好
        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // 显示提示
        showingLanguageAlert = true
    }
    
    private func createDefaultCategories() {
        let defaultCategories = [
            ("特斯拉充电站", "#FF9500", "bolt.circle.fill", 0),
            ("小鹏充电站", "#007AFF", "bolt.circle.fill", 1),
            ("蔚来换电站", "#34C759", "bolt.circle.fill", 2),
            ("国家电网", "#AF52DE", "bolt.circle.fill", 3)
        ]
        
        for categoryData in defaultCategories {
            let category = ChargingStationCategory(name: categoryData.0, color: categoryData.1, icon: categoryData.2, sortOrder: categoryData.3)
            modelContext.insert(category)
        }
    }
    
    // CSV 导出功能
    private func exportCSV() {
        isExporting = true
        backupMessage = nil
        
        // 格式化日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 构建 CSV 内容
        var csvContent = "日期,充电地点,记录类型,充电度数(kWh),电费金额,服务费,总金额,停车费,优惠金额,积分,极能度数(kWh),备注\n"
        
        for record in chargingRecords.sorted(by: { $0.chargingTime > $1.chargingTime }) {
            let date = dateFormatter.string(from: record.chargingTime)
            let location = record.location
            let recordType = record.recordType
            let electricityAmount = String(format: "%.1f", record.electricityAmount)
            let amount = String(format: "%.2f", record.amount)
            let serviceFee = String(format: "%.2f", record.serviceFee)
            let totalAmount = String(format: "%.2f", record.totalAmount)
            let parkingFee = String(format: "%.2f", record.parkingFee)
            let discountAmount = String(format: "%.2f", record.discountAmount)
            let points = String(format: "%.0f", record.points)
            let extremeEnergyKwh = String(format: "%.3f", record.extremeEnergyKwh)
            let notes = record.notes.isEmpty ? "无" : record.notes
            
            csvContent += "\(date),\(location),\(recordType),\(electricityAmount),\(amount),\(serviceFee),\(totalAmount),\(parkingFee),\(discountAmount),\(points),\(extremeEnergyKwh),\(notes)\n"
        }
        
        // 保存到临时文件并打开分享
        if let csvData = csvContent.data(using: .utf8) {
            // 添加UTF-8 BOM以确保Excel正确显示中文
            var data = Data()
            data.append(contentsOf: [0xEF, 0xBB, 0xBF]) // UTF-8 BOM
            data.append(csvData)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "充电记录_\(dateString).csv"
            
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let filePath = tempDir.appendingPathComponent(fileName)
            
            do {
                try data.write(to: filePath)
                isExporting = false
                exportedFileURL = IdentifiableURL(filePath)
                
                // 显示成功消息
                backupMessage = "准备分享文件"
                
                // 3秒后清除消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    backupMessage = nil
                }
            } catch {
                isExporting = false
                backupMessage = "导出失败"
                
                // 3秒后清除消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    backupMessage = nil
                }
            }
        }
    }
    
    // iCloud 备份功能
    private func backupToiCloud() {
        isBackingUp = true
        backupMessage = nil
        
        // 构建备份数据结构
        let backupData: [String: Any] = [
            "version": "1.0",
            "timestamp": Date().timeIntervalSince1970,
            "records": chargingRecords.map { record in
                [
                    "id": record.id.uuidString,
                    "location": record.location,
                    "amount": Double(String(format: "%.3f", record.amount)) ?? record.amount,
                    "electricityAmount": Double(String(format: "%.3f", record.electricityAmount)) ?? record.electricityAmount,
                    "serviceFee": Double(String(format: "%.3f", record.serviceFee)) ?? record.serviceFee,
                    "totalAmount": Double(String(format: "%.3f", record.totalAmount)) ?? record.totalAmount,
                    "chargingTime": record.chargingTime.timeIntervalSince1970,
                    "parkingFee": Double(String(format: "%.3f", record.parkingFee)) ?? record.parkingFee,
                    "discountAmount": Double(String(format: "%.3f", record.discountAmount)) ?? record.discountAmount,
                    "points": record.points,
                    "extremeEnergyKwh": Double(String(format: "%.3f", record.extremeEnergyKwh)) ?? record.extremeEnergyKwh,
                    "notes": record.notes,
                    "stationType": record.stationType,
                    "recordType": record.recordType
                ]
            },
            "categories": categories.map { category in
                [
                    "id": category.id.uuidString,
                    "name": category.name,
                    "color": category.color,
                    "icon": category.icon,
                    "createdAt": category.createdAt.timeIntervalSince1970,
                    "sortOrder": category.sortOrder
                ]
            },
            "settings": (userSettings.first.map { settings -> [String: Any] in
                [
                    "id": settings.id.uuidString,
                    "currencyCode": settings.currencyCode,
                    "currencySymbol": settings.currencySymbol,
                    "currencyName": settings.currencyName,
                    "language": settings.language
                ]
            }) as Any
        ]
        
        // 序列化为JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
            
            // 保存到临时文件
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            
            // 获取应用名字
            let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String 
                ?? Bundle.main.infoDictionary?["CFBundleName"] as? String 
                ?? "ChargerNote"
            
            let fileName = "\(appName)_\(dateString).json"
            
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let filePath = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: filePath)
            
            isBackingUp = false
            iCloudBackupURL = IdentifiableURL(filePath)
            
            // 显示成功消息
            backupMessage = "准备保存到iCloud"
            
            // 3秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                backupMessage = nil
            }
        } catch {
            isBackingUp = false
            backupMessage = "备份失败: \(error.localizedDescription)"
            
            // 3秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                backupMessage = nil
            }
        }
    }
    
    // iCloud 恢复功能
    private func restoreFromiCloud() {
        showingDocumentPicker = true
    }
    
    // 从备份文件恢复数据
    private func restoreFromBackupFile(url: URL) {
        isRestoring = true
        backupMessage = nil
        
        do {
            // 获取安全作用域访问权限
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // 读取备份文件
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let backupData = json else {
                throw NSError(domain: "BackupError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的备份文件"])
            }
            
            // 验证版本
            if let version = backupData["version"] as? String, version != "1.0" {
                throw NSError(domain: "BackupError", code: 2, userInfo: [NSLocalizedDescriptionKey: "不支持的备份版本"])
            }
            
            // 恢复数据
            if let recordsData = backupData["records"] as? [[String: Any]] {
                for recordData in recordsData {
                    guard let location = recordData["location"] as? String,
                          let amountValue = recordData["amount"],
                          let electricityAmountValue = recordData["electricityAmount"],
                          let serviceFeeValue = recordData["serviceFee"],
                          let totalAmountValue = recordData["totalAmount"],
                          let chargingTimeInterval = recordData["chargingTime"] as? TimeInterval,
                          let parkingFeeValue = recordData["parkingFee"],
                          let notes = recordData["notes"] as? String,
                          let stationType = recordData["stationType"] as? String,
                          let recordType = recordData["recordType"] as? String else {
                        continue
                    }
                    
                    // 处理金额，确保是Double类型
                    let amount = (amountValue as? Double) ?? 0.0
                    let electricityAmount = (electricityAmountValue as? Double) ?? 0.0
                    let serviceFee = (serviceFeeValue as? Double) ?? 0.0
                    let totalAmount = (totalAmountValue as? Double) ?? 0.0
                    let parkingFee = (parkingFeeValue as? Double) ?? 0.0
                    
                    // 处理新字段（向后兼容：如果备份文件中没有这些字段，使用默认值0）
                    let discountAmount = (recordData["discountAmount"] as? Double) ?? 0.0
                    let points = (recordData["points"] as? Double) ?? 0.0
                    let extremeEnergyKwh = (recordData["extremeEnergyKwh"] as? Double) ?? 0.0
                    
                    let chargingTime = Date(timeIntervalSince1970: chargingTimeInterval)
                    
                    let record = ChargingRecord(
                        location: location,
                        amount: amount,
                        electricityAmount: electricityAmount,
                        serviceFee: serviceFee,
                        totalAmount: totalAmount,
                        chargingTime: chargingTime,
                        parkingFee: parkingFee,
                        notes: notes,
                        stationType: stationType,
                        recordType: recordType,
                        points: points,
                        discountAmount: discountAmount,
                        extremeEnergyKwh: extremeEnergyKwh
                    )
                    
                    modelContext.insert(record)
                }
            }
            
            // 恢复充电站点分类
            if let categoriesData = backupData["categories"] as? [[String: Any]] {
                for categoryData in categoriesData {
                    guard let name = categoryData["name"] as? String,
                          let color = categoryData["color"] as? String,
                          let icon = categoryData["icon"] as? String else {
                        continue
                    }
                    
                    // 检查是否已存在同名分类
                    let existingCategory = categories.first { $0.name == name }
                    if existingCategory == nil {
                        let sortOrder = categoryData["sortOrder"] as? Int ?? categories.count
                        let category = ChargingStationCategory(name: name, color: color, icon: icon, sortOrder: sortOrder)
                        modelContext.insert(category)
                    }
                }
            }
            
            // 恢复用户设置
            if let settingsData = backupData["settings"] as? [String: Any] {
                if let currencyCode = settingsData["currencyCode"] as? String,
                   let currencySymbol = settingsData["currencySymbol"] as? String,
                   let currencyName = settingsData["currencyName"] as? String {
                    let language = settingsData["language"] as? String ?? "zh-Hans" // 默认中文
                    if userSettings.isEmpty {
                        let newSettings = UserSettings(
                            currencyCode: currencyCode,
                            currencySymbol: currencySymbol,
                            currencyName: currencyName,
                            language: language
                        )
                        modelContext.insert(newSettings)
                    } else {
                        let settings = userSettings.first!
                        settings.currencyCode = currencyCode
                        settings.currencySymbol = currencySymbol
                        settings.currencyName = currencyName
                        settings.language = language
                    }
                }
            } else {
                // 如果没有设置数据，确保存在默认设置
                if userSettings.isEmpty {
                    let defaultSettings = UserSettings()
                    modelContext.insert(defaultSettings)
                }
            }
            
            isRestoring = false
            backupMessage = "恢复成功"
            
            // 3秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                backupMessage = nil
            }
        } catch {
            isRestoring = false
            backupMessage = "恢复失败: \(error.localizedDescription)"
            
            // 3秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                backupMessage = nil
            }
        }
    }
    
    private func deleteCategory(_ category: ChargingStationCategory) {
        modelContext.delete(category)
    }
    
    // 删除所有数据
    private func deleteAllData() {
        // 删除所有充电记录
        for record in chargingRecords {
            modelContext.delete(record)
        }
        
        // 删除所有充电站点分类
        for category in categories {
            modelContext.delete(category)
        }
        
        // 显示成功消息
        backupMessage = "已清除所有数据"
        
        // 3秒后清除消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            backupMessage = nil
        }
    }
}


struct CollapsibleSettingsSection<Content: View>: View {
    let title: String
    let content: Content
    @Binding var isExpanded: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏 - 可点击
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 增大折叠图标可点击区域
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.cardBackground(for: colorScheme))
            
            // 顶部分隔线
            if isExpanded {
                Rectangle()
                    .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .frame(height: 0.5)
            }
            
            // 内容 - 根据折叠状态显示/隐藏
            if isExpanded {
                VStack(spacing: 0) {
                    content
                }
                .background(Color.cardBackground(for: colorScheme))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    let action: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                            Text("添加")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.cardBackground(for: colorScheme))
            
            // 内容
            VStack(spacing: 0) {
                content
            }
            .background(Color.cardBackground(for: colorScheme))
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsRow: View {
    let icon: String?
    let title: String
    let value: String?
    let titleColor: Color
    let hasArrow: Bool
    let hasCheckmark: Bool
    let showSeparator: Bool
    let action: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    init(icon: String? = nil, title: String, value: String? = nil, titleColor: Color = .primary, hasArrow: Bool = false, hasCheckmark: Bool = false, showSeparator: Bool = true, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.titleColor = titleColor
        self.hasArrow = hasArrow
        self.hasCheckmark = hasCheckmark
        self.showSeparator = showSeparator
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action ?? {}) {
                HStack(spacing: 12) {
                    if let icon = icon {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: icon)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(titleColor)
                    
                    Spacer()
                    
                    if let value = value {
                        Text(value)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    } else if hasArrow {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else if hasCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cardBackground(for: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
            
            // 底部分隔线
            if showSeparator {
                Rectangle()
                    .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .frame(height: 0.5)
                    .padding(.leading, icon != nil ? 52 : 16)
            }
        }
    }
}

struct CategoryRow: View {
    let category: ChargingStationCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.color).opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: category.color))
            }
            
            Text(category.name)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

// 充电站管理弹窗
struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChargingStationCategory.sortOrder) private var categories: [ChargingStationCategory]
    @Query private var chargingRecords: [ChargingRecord]
    @Binding var showingAddCategory: Bool
    @Binding var editingCategory: ChargingStationCategory?
    @State private var categoryToDelete: ChargingStationCategory?
    @State private var showingDeleteConfirmation = false
    @State private var editMode: EditMode = .inactive
    @State private var internalEditingCategory: ChargingStationCategory?
    @State private var showingInternalAddCategory = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.id) { category in
                    SwipeableCategoryRow(
                        category: category,
                        onEdit: {
                            internalEditingCategory = category
                        },
                        onDelete: {
                            categoryToDelete = category
                            showingDeleteConfirmation = true
                        }
                    )
                }
                .onMove(perform: moveCategories)
            }
            .navigationTitle("充电站管理")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingInternalAddCategory = true
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        Button(action: {
                            editMode = editMode == .active ? .inactive : .active
                        }) {
                            Text(editMode == .active ? "完成" : "排序")
                        }
                    }
                }
            }
            .alert("删除充电站", isPresented: $showingDeleteConfirmation) {
                Button("取消", role: .cancel) {
                    categoryToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category)
                    }
                }
            } message: {
                if let category = categoryToDelete {
                    let recordCount = chargingRecords.filter { $0.stationType == category.name }.count
                    if recordCount > 0 {
                        Text("该充电站有 \(recordCount) 条充电记录，删除后这些记录的站点类型将保留。确定要删除吗？")
                    } else {
                        Text("确定要删除该充电站吗？")
                    }
                }
            }
            .sheet(isPresented: $showingInternalAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $internalEditingCategory) { category in
                EditCategoryView(category: category)
            }
        }
    }
    
    private func deleteCategory(_ category: ChargingStationCategory) {
        modelContext.delete(category)
        categoryToDelete = nil
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var updatedCategories = categories
        
        // 移动项目
        updatedCategories.move(fromOffsets: source, toOffset: destination)
        
        // 更新所有类别的sortOrder
        for (index, category) in updatedCategories.enumerated() {
            category.sortOrder = index
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ChargingStationCategory]
    @State private var categoryName = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "bolt.circle.fill"
    
    private let availableColors: [(Color, String)] = [
        (.red, "#FF3B30"),
        (.orange, "#FF9500"),
        (.yellow, "#FFCC00"),
        (.green, "#34C759"),
        (.blue, "#007AFF"),
        (.purple, "#AF52DE"),
        (.pink, "#FF2D92"),
        (.cyan, "#5AC8FA"),
        (.mint, "#00C7BE"),
        (.indigo, "#5856D6")
    ]
    
    private let availableIcons = [
        "bolt.circle.fill",
        "flame.fill",
        "battery.100.bolt",
        "bolt.fill",
        "bolt.horizontal.fill",
        "battery.100",
        "bolt.car.fill",
        "battery.charging.100"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("充电站名称", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // 颜色选择器
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择颜色")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableColors, id: \.1) { color, hex in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 图标选择器
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择图标")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .gray)
                            }
                            .overlay(
                                Circle()
                                    .stroke(selectedIcon == icon ? selectedColor : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("添加充电站")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let hexColor = availableColors.first { $0.0 == selectedColor }?.1 ?? "#007AFF"
        let sortOrder = categories.count
        let category = ChargingStationCategory(
            name: categoryName,
            color: hexColor,
            icon: selectedIcon,
            sortOrder: sortOrder
        )
        modelContext.insert(category)
        dismiss()
    }
}

// 编辑充电站视图
struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let category: ChargingStationCategory
    @State private var categoryName = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "bolt.circle.fill"
    
    private let availableColors: [(Color, String)] = [
        (.red, "#FF3B30"),
        (.orange, "#FF9500"),
        (.yellow, "#FFCC00"),
        (.green, "#34C759"),
        (.blue, "#007AFF"),
        (.purple, "#AF52DE"),
        (.pink, "#FF2D92"),
        (.cyan, "#5AC8FA"),
        (.mint, "#00C7BE"),
        (.indigo, "#5856D6")
    ]
    
    private let availableIcons = [
        "bolt.circle.fill",
        "flame.fill",
        "battery.100.bolt",
        "bolt.fill",
        "bolt.horizontal.fill",
        "battery.100",
        "bolt.car.fill",
        "battery.charging.100"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("充电站名称", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // 颜色选择器
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择颜色")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableColors, id: \.1) { color, hex in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 图标选择器
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择图标")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .gray)
                            }
                            .overlay(
                                Circle()
                                    .stroke(selectedIcon == icon ? selectedColor : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("编辑充电站")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
            .onAppear {
                categoryName = category.name
                selectedIcon = category.icon
                // 根据hex颜色找到对应的Color
                if let colorPair = availableColors.first(where: { $0.1 == category.color }) {
                    selectedColor = colorPair.0
                }
            }
        }
    }
    
    private func updateCategory() {
        let hexColor = availableColors.first { $0.0 == selectedColor }?.1 ?? "#007AFF"
        category.name = categoryName
        category.color = hexColor
        category.icon = selectedIcon
        dismiss()
    }
}

// 文件分享视图
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 不需要更新
    }
}

// 文档选择器
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .data])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void
        
        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onDocumentPicked(url)
        }
    }
}

// URL包装器，使其可被识别为可选类型
struct IdentifiableURL: Identifiable {
    let id: String
    let url: URL
    
    init(_ url: URL) {
        self.url = url
        self.id = url.absoluteString
    }
}

// Color扩展，支持十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 可左滑的站点分类行组件
struct SwipeableCategoryRow: View {
    let category: ChargingStationCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var dragDirection: DragDirection? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    private let actionButtonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = 50
    
    enum DragDirection {
        case horizontal
        case vertical
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // 背景按钮 - 固定在右侧
                HStack(spacing: 0) {
                    Spacer()
                    
                    // 编辑按钮
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                        Text("编辑")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .frame(width: actionButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.blue)
                    .onTapGesture {
                        withAnimation {
                            offset = 0
                        }
                        onEdit()
                    }
                    
                    // 删除按钮
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                        Text("删除")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .frame(width: actionButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .onTapGesture {
                        withAnimation {
                            offset = 0
                        }
                        onDelete()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 前景内容
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: category.color).opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: category.color))
                    }
                    
                    Text(category.name)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground(for: colorScheme))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .offset(x: offset)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            if offset < 0 {
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { gesture in
                            // 判断滑动方向
                            if dragDirection == nil {
                                let horizontalAmount = abs(gesture.translation.width)
                                let verticalAmount = abs(gesture.translation.height)
                                
                                if horizontalAmount > verticalAmount * 1.5 {
                                    dragDirection = .horizontal
                                } else {
                                    dragDirection = .vertical
                                }
                            }
                            
                            // 只有在水平方向时才处理左滑
                            if dragDirection == .horizontal {
                                let translation = gesture.translation.width
                                if translation < 0 {
                                    offset = max(translation, -(actionButtonWidth * 2))
                                } else if offset < 0 {
                                    offset = min(0, offset + translation)
                                }
                            }
                        }
                        .onEnded { gesture in
                            dragDirection = nil
                            
                            let horizontalAmount = abs(gesture.translation.width)
                            let verticalAmount = abs(gesture.translation.height)
                            
                            if horizontalAmount > verticalAmount * 1.5 {
                                let translation = gesture.translation.width
                                withAnimation(.spring()) {
                                    if translation < -swipeThreshold && offset > -(actionButtonWidth * 2) {
                                        offset = -(actionButtonWidth * 2)
                                    } else if translation > swipeThreshold && offset < 0 {
                                        offset = 0
                                    } else if offset < -(actionButtonWidth) {
                                        offset = -(actionButtonWidth * 2)
                                    } else {
                                        offset = 0
                                    }
                                }
                            }
                        }
                )
            }
        }
        .frame(height: 72)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [ChargingRecord.self, ChargingStationCategory.self], inMemory: true)
}
