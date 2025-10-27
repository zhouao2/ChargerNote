//
//  SettingsView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    @Query private var chargingRecords: [ChargingRecord]
    @Query private var categories: [ChargingStationCategory]
    @Query private var userSettings: [UserSettings]
    @State private var selectedCurrency: Currency = .cny
    @State private var showingAddCategory = false
    @State private var editingCategory: ChargingStationCategory?
    @State private var showingCategoryManagement = false
    
    // 折叠状态
    @State private var isAppearanceExpanded = false
    @State private var isCurrencyExpanded = false
    @State private var isStationExpanded = false
    @State private var isDataExpanded = false
    @State private var isDangerExpanded = false
    
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
                                
                                // 充电站点管理
                                CollapsibleSettingsSection(title: "充电站点管理", isExpanded: $isStationExpanded) {
                                    SettingsRow(icon: "mappin.and.ellipse", title: "管理充电站点", hasArrow: true, action: {
                                        showingCategoryManagement = true
                                    })
                                }
                                
                                // 数据管理
                                CollapsibleSettingsSection(title: "数据管理", isExpanded: $isDataExpanded) {
                                    SettingsRow(icon: "square.and.arrow.down", title: "导出CSV数据", hasArrow: true)
                                    SettingsRow(icon: "icloud.and.arrow.up", title: "备份到iCloud", hasArrow: true)
                                    SettingsRow(icon: "icloud.and.arrow.down", title: "从iCloud恢复", hasArrow: true)
                                }
                                
                                // 危险操作
                                CollapsibleSettingsSection(title: "危险操作", isExpanded: $isDangerExpanded) {
                                    SettingsRow(icon: "trash", title: "清除所有数据", titleColor: .red, hasArrow: true)
                                }
                                
                                // 应用信息
                                SettingsSection(title: "应用信息") {
                                    SettingsRow(title: "版本号", value: "1.0.0")
                                    SettingsRow(title: "构建版本", value: "2025.10.25")
                                    SettingsRow(title: "开发者", value: "Zhou Ao", showSeparator: false)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 100) // 为底部导航留出空间
                        }
                    }
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
    
    private func createDefaultCategories() {
        let defaultCategories = [
            ("特斯拉充电站", "#FF9500", "bolt.circle.fill"),
            ("小鹏充电站", "#007AFF", "bolt.circle.fill"),
            ("蔚来换电站", "#34C759", "bolt.circle.fill"),
            ("国家电网", "#AF52DE", "bolt.circle.fill")
        ]
        
        for (name, color, icon) in defaultCategories {
            let category = ChargingStationCategory(name: name, color: color, icon: icon)
            modelContext.insert(category)
        }
    }
    
    private func deleteCategory(_ category: ChargingStationCategory) {
        modelContext.delete(category)
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

// 充电站点管理弹窗
struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ChargingStationCategory]
    @Binding var showingAddCategory: Bool
    @Binding var editingCategory: ChargingStationCategory?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.id) { category in
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
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                editingCategory = category
                                dismiss()
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Button(action: {
                                deleteCategory(category)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("充电站点管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func deleteCategory(_ category: ChargingStationCategory) {
        modelContext.delete(category)
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var categoryName = ""
    @State private var selectedColor: Color = .blue
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("站点名称", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // 颜色选择器
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
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("添加站点")
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
        let category = ChargingStationCategory(
            name: categoryName,
            color: hexColor,
            icon: "bolt.circle.fill"
        )
        modelContext.insert(category)
        dismiss()
    }
}

// 编辑站点视图
struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let category: ChargingStationCategory
    @State private var categoryName = ""
    @State private var selectedColor: Color = .blue
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("站点名称", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // 颜色选择器
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
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("编辑站点")
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
        dismiss()
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

#Preview {
    SettingsView()
        .modelContainer(for: [ChargingRecord.self, ChargingStationCategory.self], inMemory: true)
}
