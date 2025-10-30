//
//  ChargerNoteApp.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData

@main
struct ChargerNoteApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var backupManager = DataBackupManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            ChargingRecord.self,
            ChargingStationCategory.self,
            UserSettings.self,
        ])
        
        // 创建新的配置 - 使用固定的URL避免冲突
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChargerNote.store")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: url
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ModelContainer error: \(error)")
            print("Attempting to clean database files...")
            
            // 删除所有可能的数据库文件
            let fileManager = FileManager.default
            let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            
            // 删除当前配置的数据库文件
            let fileExtensions = ["", "-shm", "-wal"]
            for ext in fileExtensions {
                let fileURL = appSupportDir.appendingPathComponent("ChargerNote.store\(ext)")
                if fileManager.fileExists(atPath: fileURL.path) {
                    try? fileManager.removeItem(at: fileURL)
                    print("Removed: \(fileURL.lastPathComponent)")
                }
            }
            
            // 也删除旧的 default.store 文件（如果存在）
            for ext in fileExtensions {
                let oldFileURL = appSupportDir.appendingPathComponent("default.store\(ext)")
                if fileManager.fileExists(atPath: oldFileURL.path) {
                    try? fileManager.removeItem(at: oldFileURL)
                    print("Removed old: \(oldFileURL.lastPathComponent)")
                }
            }
            
            // 重新尝试创建
            do {
                print("Recreating ModelContainer...")
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("Failed to recreate ModelContainer: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(backupManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onAppear {
                    performInitialBackupCheck()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // App 进入后台时自动备份
                performAutoBackup()
            }
        }
    }
    
    // MARK: - 备份相关方法
    
    /// 首次启动时检查本地备份
    private func performInitialBackupCheck() {
        Task {
            do {
                let modelContext = sharedModelContainer.mainContext
                let recordsCount = try modelContext.fetchCount(FetchDescriptor<ChargingRecord>())
                
                // 如果本地没有数据，尝试从备份恢复
                if recordsCount == 0 {
                    try await backupManager.restoreFromLocalBackup(modelContext: modelContext)
                }
            } catch {
                print("⚠️ 初始备份检查失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 执行自动备份
    private func performAutoBackup() {
        Task { @MainActor in
            do {
                let modelContext = sharedModelContainer.mainContext
                
                // 获取所有数据
                let recordsDescriptor = FetchDescriptor<ChargingRecord>()
                let records = try modelContext.fetch(recordsDescriptor)
                
                let categoriesDescriptor = FetchDescriptor<ChargingStationCategory>()
                let categories = try modelContext.fetch(categoriesDescriptor)
                
                // 执行自动备份
                try await backupManager.performAutoBackup(records: records, categories: categories)
            } catch {
                print("⚠️ 自动备份失败: \(error.localizedDescription)")
            }
        }
    }
}
