//
//  ManualInputView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit

struct ManualInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \ChargingStationCategory.sortOrder) private var categories: [ChargingStationCategory]
    @Query private var userSettings: [UserSettings]
    
    let editingRecord: ChargingRecord?
    
    private var currencySymbol: String {
        userSettings.first?.currencySymbol ?? "¥"
    }
    
    @State private var totalAmount: String = ""
    @State private var electricityAmount: String = ""
    @State private var serviceFee: String = ""
    @State private var location: String = ""
    @State private var electricityKwh: String = ""
    @State private var chargingTime: Date = Date()
    @State private var parkingFee: String = "0.00"
    @State private var notes: String = ""
    @State private var selectedRecordType: String = "充电"
    @State private var currentEditingField: EditingField?
    @State private var showingLocationPicker = false
    @State private var showingDatePicker = false
    @FocusState private var notesFieldFocused: Bool
    
    // 是否显示数字键盘
    private var shouldShowKeypad: Bool {
        currentEditingField != nil
    }
    
    init(editingRecord: ChargingRecord? = nil) {
        self.editingRecord = editingRecord
    }
    
    enum EditingField {
        case electricityAmount, serviceFee, electricityKwh, parkingFee
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部导航
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("记一笔")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 占位，保持居中
                        Color.clear
                            .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.cardBackground(for: colorScheme))
                    
                    // 充电记账标题
                    HStack {
                        Text("充电记账")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.cardBackground(for: colorScheme))
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // 金额输入区域
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(String(format: "%.2f", calculatedTotalAmount))
                                            .font(.system(size: 60, weight: .light))
                                            .foregroundColor(.blue)
                                        
                                        Text("实付金额")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: "camera")
                                                .font(.system(size: 20))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text("拍照")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 24)
                                .background(Color.cardBackground(for: colorScheme))
                            }
                            
                            // 详细信息输入区域
                            VStack(spacing: 0) {
                                Button(action: {
                                    notesFieldFocused = false  // 隐藏备注键盘
                                    currentEditingField = nil  // 隐藏数字键盘
                                    showingLocationPicker = true
                                }) {
                                    DetailInputRow(
                                        icon: "location",
                                        title: "充电地点",
                                        value: location.isEmpty ? "请选择" : location,
                                        hasArrow: true
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false  // 隐藏备注键盘
                                    currentEditingField = .electricityKwh
                                }) {
                                    DetailInputRow(
                                        icon: "bolt",
                                        title: "充电度数",
                                        value: electricityKwh.isEmpty ? "0.0 kWh" : "\(electricityKwh) kWh",
                                        hasArrow: false,
                                        isSelected: currentEditingField == .electricityKwh
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false  // 隐藏备注键盘
                                    currentEditingField = .electricityAmount
                                }) {
                                    DetailInputRow(
                                        icon: "yensign",
                                        title: "电费金额",
                                        value: electricityAmount.isEmpty ? "\(currencySymbol)0.00" : "\(currencySymbol)\(electricityAmount)",
                                        hasArrow: false,
                                        isSelected: currentEditingField == .electricityAmount
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false  // 隐藏备注键盘
                                    currentEditingField = .serviceFee
                                }) {
                                    DetailInputRow(
                                        icon: "hand.raised",
                                        title: "服务费",
                                        value: serviceFee.isEmpty ? "\(currencySymbol)0.00" : "\(currencySymbol)\(serviceFee)",
                                        hasArrow: false,
                                        isSelected: currentEditingField == .serviceFee
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false  // 隐藏备注键盘
                                    currentEditingField = nil  // 隐藏数字键盘
                                    showingDatePicker = true
                                }) {
                                    DetailInputRow(
                                        icon: "clock",
                                        title: "充电时间",
                                        value: formatDate(chargingTime),
                                        hasArrow: true
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false  // 隐藏备注键盘
                                    currentEditingField = .parkingFee
                                }) {
                                    DetailInputRow(
                                        icon: "parkingsign",
                                        title: "停车费",
                                        value: parkingFee.isEmpty ? "\(currencySymbol)0.00" : "\(currencySymbol)\(parkingFee)",
                                        hasArrow: false,
                                        isSelected: currentEditingField == .parkingFee
                                    )
                                }
                                
                                // 备注输入行
                                HStack(spacing: 12) {
                                    // 图标
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "note.text")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // 标题
                                    Text("备注")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // 输入框
                                    TextField("点击输入备注", text: $notes)
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.trailing)
                                        .focused($notesFieldFocused)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.cardBackground(for: colorScheme))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.cardBackground(for: colorScheme))
                            .padding(.top, 16)
                        }
                    }
                    
                    if shouldShowKeypad {
                        Spacer()
                        
                        // 数字键盘
                        VStack(spacing: 0) {
                            HStack(spacing: 4) {
                                // 数字键盘
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        KeypadButton("7", action: { handleKeypadInput("7") })
                                        KeypadButton("8", action: { handleKeypadInput("8") })
                                        KeypadButton("9", action: { handleKeypadInput("9") })
                                    }
                                    
                                    HStack(spacing: 4) {
                                        KeypadButton("4", action: { handleKeypadInput("4") })
                                        KeypadButton("5", action: { handleKeypadInput("5") })
                                        KeypadButton("6", action: { handleKeypadInput("6") })
                                    }
                                    
                                    HStack(spacing: 4) {
                                        KeypadButton("1", action: { handleKeypadInput("1") })
                                        KeypadButton("2", action: { handleKeypadInput("2") })
                                        KeypadButton("3", action: { handleKeypadInput("3") })
                                    }
                                    
                                    HStack(spacing: 4) {
                                        KeypadButton(".", action: { handleKeypadInput(".") })
                                        KeypadButton("0", action: { handleKeypadInput("0") })
                                        KeypadButton(systemImage: "delete.left", action: handleDelete)
                                    }
                                }
                                .padding(8)
                                
                                // 右侧操作按钮
                                VStack(spacing: 4) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            currentEditingField = nil  // 隐藏键盘
                                        }
                                    }) {
                                        Text("完成")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(maxHeight: .infinity)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: saveRecord) {
                                        Text("确定")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(maxHeight: .infinity)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                                .frame(width: 80)
                                .padding(8)
                            }
                            .frame(height: 240)
                        }
                        .background(Color.cardBackground(for: colorScheme))
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1),
                            alignment: .top
                        )
                        .transition(.move(edge: .bottom))
                    } else {
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(categories: categories, selectedLocation: $location)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $chargingTime)
        }
        .onAppear {
            if let record = editingRecord {
                // 加载编辑数据
                totalAmount = String(format: "%.2f", record.totalAmount)
                electricityAmount = String(format: "%.2f", record.amount)
                serviceFee = String(format: "%.2f", record.serviceFee)
                location = record.location
                electricityKwh = String(format: "%.1f", record.electricityAmount)
                chargingTime = record.chargingTime
                parkingFee = String(format: "%.2f", record.parkingFee)
                notes = record.notes
            } else if location.isEmpty && !categories.isEmpty {
                // 新建记录，使用第一个分类作为默认值
                location = categories.first?.name ?? ""
            }
        }
    }
    
    // 计算属性：实付金额（自动计算）
    private var calculatedTotalAmount: Double {
        let electricity = Double(electricityAmount) ?? 0
        let service = Double(serviceFee) ?? 0
        return electricity + service
    }
    
    // 计算属性：显示金额
    private var displayAmount: String {
        switch currentEditingField {
        case .electricityAmount:
            return electricityAmount.isEmpty ? "0.00" : electricityAmount
        case .serviceFee:
            return serviceFee.isEmpty ? "0.00" : serviceFee
        case .electricityKwh:
            return electricityKwh.isEmpty ? "0.0" : electricityKwh
        case .parkingFee:
            return parkingFee.isEmpty ? "0.00" : parkingFee
        case .none:
            return "0.00"
        }
    }
    
    // 计算属性：显示描述
    private var displayDescription: String {
        switch currentEditingField {
        case .electricityAmount:
            return "电费金额"
        case .serviceFee:
            return "服务费"
        case .electricityKwh:
            return "充电度数 (kWh)"
        case .parkingFee:
            return "停车费"
        case .none:
            return ""
        }
    }
    
    // 处理数字输入
    private func handleKeypadInput(_ digit: String) {
        switch currentEditingField {
        case .electricityAmount:
            if digit == "." && electricityAmount.contains(".") { return }
            electricityAmount += digit
        case .serviceFee:
            if digit == "." && serviceFee.contains(".") { return }
            serviceFee += digit
        case .electricityKwh:
            if digit == "." && electricityKwh.contains(".") { return }
            electricityKwh += digit
        case .parkingFee:
            if digit == "." && parkingFee.contains(".") { return }
            parkingFee += digit
        case .none:
            break
        }
    }
    
    // 处理删除
    private func handleDelete() {
        switch currentEditingField {
        case .electricityAmount:
            if !electricityAmount.isEmpty {
                electricityAmount.removeLast()
            }
        case .serviceFee:
            if !serviceFee.isEmpty {
                serviceFee.removeLast()
            }
        case .electricityKwh:
            if !electricityKwh.isEmpty {
                electricityKwh.removeLast()
            }
        case .parkingFee:
            if !parkingFee.isEmpty {
                parkingFee.removeLast()
            }
        case .none:
            break
        }
    }
    
    private func saveRecord() {
        let electricity = Double(electricityAmount) ?? 0
        let service = Double(serviceFee) ?? 0
        let kwh = Double(electricityKwh) ?? 0
        let parking = Double(parkingFee) ?? 0
        let total = calculatedTotalAmount // 使用计算的实付金额
        
        if let record = editingRecord {
            // 更新现有记录
            record.location = location
            record.amount = electricity
            record.electricityAmount = kwh
            record.serviceFee = service
            record.totalAmount = total
            record.chargingTime = chargingTime
            record.parkingFee = parking
            record.notes = notes
            record.stationType = getStationType(from: location)
        } else {
            // 创建新记录
            let record = ChargingRecord(
                location: location,
                amount: electricity,
                electricityAmount: kwh,
                serviceFee: service,
                totalAmount: total,
                chargingTime: chargingTime,
                parkingFee: parking,
                notes: notes,
                stationType: getStationType(from: location),
                recordType: selectedRecordType
            )
            modelContext.insert(record)
        }
        
        dismiss()
    }
    
    private func getStationType(from location: String) -> String {
        if location.contains("特斯拉") {
            return "特斯拉"
        } else if location.contains("小鹏") {
            return "小鹏"
        } else if location.contains("蔚来") {
            return "蔚来"
        } else {
            return "国家电网"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "M月d日 HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

struct DetailInputRow: View {
    let icon: String
    let title: String
    let value: String
    var hasArrow: Bool = false
    var hasCheckmark: Bool = false
    var hasX: Bool = false
    var isSelected: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                } else if hasCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else if hasX {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.05) : Color.cardBackground(for: colorScheme))
    }
}

struct KeypadButton: View {
    let content: String
    let systemImage: String?
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(_ text: String, action: @escaping () -> Void) {
        self.content = text
        self.systemImage = nil
        self.action = action
    }
    
    init(systemImage: String, action: @escaping () -> Void) {
        self.content = ""
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                } else {
                    Text(content)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// 日期时间选择器
struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("选择时间", selection: $tempDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                
                Spacer()
            }
            .navigationTitle("选择充电时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        selectedDate = tempDate
                        dismiss()
                    }
                }
            }
        }
    }
}

// 充电地点选择器
struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [ChargingStationCategory]
    @Binding var selectedLocation: String
    
    // 按照 sortOrder 排序的分类列表
    private var sortedCategories: [ChargingStationCategory] {
        categories.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedCategories, id: \.id) { category in
                    Button(action: {
                        selectedLocation = category.name
                        dismiss()
                    }) {
                        HStack {
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
                            
                            if selectedLocation == category.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("选择充电地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ManualInputView()
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
