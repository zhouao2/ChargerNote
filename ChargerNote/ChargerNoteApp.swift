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
            print("Attempting to clean old database files...")
            
            // 只有在创建失败时才删除旧数据
            let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("default.store")
            
            // 删除所有相关文件
            let fileExtensions = ["", "-shm", "-wal"]
            for ext in fileExtensions {
                let url = storeURL.path.appending(ext)
                if FileManager.default.fileExists(atPath: url) {
                    try? FileManager.default.removeItem(atPath: url)
                    print("Removed old database file: \(url)")
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
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
