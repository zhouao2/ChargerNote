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
    let extractedData: ExtractedChargingData?
    
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
    @State private var discountAmount: String = "0.00"
    @State private var points: String = "0"
    @State private var extremeEnergyKwh: String = ""
    @State private var notes: String = ""
    @State private var selectedRecordType: String = "充电"
    @State private var currentEditingField: EditingField?
    @State private var showingLocationPicker = false
    @State private var showingDatePicker = false
    @FocusState private var notesFieldFocused: Bool
    @State private var shouldClearOnNextInput: Bool = false
    
    // 是否显示数字键盘
    private var shouldShowKeypad: Bool {
        currentEditingField != nil
    }
    
    init(editingRecord: ChargingRecord? = nil, extractedData: ExtractedChargingData? = nil) {
        self.editingRecord = editingRecord
        self.extractedData = extractedData
    }
    
    enum EditingField {
        case electricityAmount, serviceFee, electricityKwh, parkingFee, discountAmount, points
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
                        
                        Text(L("manual.title"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 完成按钮
                        Button(action: saveRecord) {
                            Text(L("manual.done"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.cardBackground(for: colorScheme))
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // 💰 顶部金额区域 - Phase 1 优化
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedRecordType == "充值" ? L("manual.recharge_amount") : L("manual.total_amount"))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    // Phase 1: 缩小金额尺寸并添加动画
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(currencySymbol)
                                            .font(.system(size: 24, weight: .light))
                                            .foregroundColor(selectedRecordType == "充值" ? .purple : .blue)
                                        
                                        Text(String(format: "%.2f", calculatedTotalAmount))
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(selectedRecordType == "充值" ? .purple : .blue)
                                            .animation(.spring(response: 0.3), value: calculatedTotalAmount)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Phase 1: 计算公式显示（充值模式不显示）
                                if selectedRecordType != "充值" && hasInputValue {
                                    HStack(spacing: 4) {
                                        FormulaItem(label: L("manual.electricity_fee"), value: electricityAmount, symbol: currencySymbol, color: .primary)
                                        Text("+")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        FormulaItem(label: L("manual.service_fee"), value: serviceFee, symbol: currencySymbol, color: .primary)
                                        Text("-")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        FormulaItem(label: L("manual.discount"), value: discountAmount, symbol: currencySymbol, color: .green)
                                    }
                                    .font(.system(size: 12))
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(Color.cardBackground(for: colorScheme))
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                            
                            Spacer().frame(height: 16)
                            
                            // 📍 Phase 1: 基本信息分组
                            VStack(spacing: 0) {
                                SectionHeader(title: L("manual.basic_info"), icon: "doc.text.fill")
                                
                                // 记录类型选择
                                VStack(spacing: 0) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                                .frame(width: 24, height: 24)
                                            Image(systemName: "square.grid.2x2")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(L("manual.record_type.charge"))
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        // 类型选择按钮
                                        HStack(spacing: 8) {
                                            RecordTypeButton(title: L("manual.record_type.charge"), icon: "bolt.fill", isSelected: selectedRecordType == "充电") {
                                                selectedRecordType = "充电"
                                            }
                                            RecordTypeButton(title: L("manual.record_type.recharge"), icon: "creditcard.fill", isSelected: selectedRecordType == "充值") {
                                                selectedRecordType = "充值"
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.cardBackground(for: colorScheme))
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false
                                    currentEditingField = nil
                                    showingLocationPicker = true
                                }) {
                                    DetailInputRow(
                                        icon: "location",
                                        title: selectedRecordType == "充值" ? L("manual.recharge_platform") : L("manual.charging_station"),
                                        value: location.isEmpty ? L("manual.select_station") : location,
                                        hasArrow: true,
                                        isEmpty: location.isEmpty
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false
                                    currentEditingField = nil
                                    showingDatePicker = true
                                }) {
                                    DetailInputRow(
                                        icon: "clock",
                                        title: selectedRecordType == "充值" ? L("manual.purchase_time") : L("manual.charging_time"),
                                        value: formatDate(chargingTime),
                                        hasArrow: true
                                    )
                                }
                                
                                // 充电电量/获得度数
                                if selectedRecordType == "充值" {
                                    Button(action: {
                                        notesFieldFocused = false
                                        currentEditingField = .electricityKwh
                                        shouldClearOnNextInput = true
                                    }) {
                                        DetailInputRow(
                                            icon: "bolt.badge.automatic",
                                            title: L("manual.acquired_kwh"),
                                            value: formatValue(electricityKwh, suffix: " kWh", defaultText: L("manual.not_entered")),
                                            hasArrow: false,
                                            isSelected: currentEditingField == .electricityKwh,
                                            valueColor: .purple,
                                            isEmpty: electricityKwh.isEmpty
                                        )
                                    }
                                } else {
                                    Button(action: {
                                        notesFieldFocused = false
                                        currentEditingField = .electricityKwh
                                        shouldClearOnNextInput = true
                                    }) {
                                        DetailInputRow(
                                            icon: "bolt",
                                            title: L("manual.electricity_kwh"),
                                            value: formatValue(electricityKwh, suffix: " kWh", defaultText: L("manual.not_entered")),
                                            hasArrow: false,
                                            isSelected: currentEditingField == .electricityKwh,
                                            isEmpty: electricityKwh.isEmpty
                                        )
                                    }
                                }
                            }
                            .background(Color.cardBackground(for: colorScheme))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 16)
                            
                            Spacer().frame(height: 16)
                            
                            // 💰 Phase 1: 费用明细分组
                            VStack(spacing: 0) {
                                SectionHeader(title: selectedRecordType == "充值" ? L("manual.recharge_details") : L("manual.cost_details"), icon: "dollarsign.circle.fill")
                                
                                // 充值模式：只显示充值金额输入
                                if selectedRecordType == "充值" {
                                    Button(action: {
                                        notesFieldFocused = false
                                        currentEditingField = .electricityAmount
                                        shouldClearOnNextInput = true
                                    }) {
                                        DetailInputRow(
                                            icon: "creditcard",
                                            title: L("manual.recharge_amount"),
                                            value: formatValue(electricityAmount, prefix: currencySymbol),
                                            hasArrow: false,
                                            isSelected: currentEditingField == .electricityAmount,
                                            valueColor: .purple,
                                            isEmpty: electricityAmount.isEmpty
                                        )
                                    }
                                    
                                    // 等价信息显示（例如：309元 = 300度）
                                    if !electricityAmount.isEmpty && !electricityKwh.isEmpty {
                                        HStack(spacing: 12) {
                                            Image(systemName: "equal.circle")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            
                                            Text("\(currencySymbol)\(electricityAmount) = \(electricityKwh) kWh")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            if let amount = Double(electricityAmount), let kwh = Double(electricityKwh), kwh > 0 {
                                                Text("\(L("text.approx"))\(currencySymbol)\(String(format: "%.2f", amount/kwh))\(L("text.per_kwh"))")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .background(Color.purple.opacity(0.05))
                                    }
                                }
                                // 充电模式：显示完整费用明细
                                else {
                                    Button(action: {
                                        notesFieldFocused = false
                                        currentEditingField = .electricityAmount
                                        shouldClearOnNextInput = true
                                    }) {
                                        DetailInputRow(
                                            icon: "yensign",
                                            title: L("manual.electricity_fee"),
                                            value: formatValue(electricityAmount, prefix: currencySymbol),
                                            hasArrow: false,
                                            isSelected: currentEditingField == .electricityAmount,
                                            isEmpty: electricityAmount.isEmpty
                                        )
                                    }
                                    
                                    Button(action: {
                                        notesFieldFocused = false
                                        currentEditingField = .serviceFee
                                        shouldClearOnNextInput = true
                                    }) {
                                        DetailInputRow(
                                            icon: "hand.raised",
                                            title: L("manual.service_fee"),
                                            value: formatValue(serviceFee, prefix: currencySymbol),
                                            hasArrow: false,
                                            isSelected: currentEditingField == .serviceFee,
                                            isEmpty: serviceFee.isEmpty
                                        )
                                    }
                                    
                                    Button(action: {
                                        notesFieldFocused = false
                                        currentEditingField = .discountAmount
                                        shouldClearOnNextInput = true
                                    }) {
                                        DetailInputRow(
                                            icon: "tag.fill",
                                            title: L("manual.discount"),
                                            value: formatValue(discountAmount, prefix: currencySymbol),
                                            hasArrow: false,
                                            isSelected: currentEditingField == .discountAmount,
                                            valueColor: .green,
                                            isEmpty: discountAmount.isEmpty || discountAmount == "0.00"
                                        )
                                    }
                                    
                                    // 实付金额分隔线和显示
                                    Divider()
                                        .padding(.horizontal, 24)
                                    
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 24, height: 24)
                                            Image(systemName: "equal")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text(L("manual.total_amount"))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(currencySymbol)\(String(format: "%.2f", calculatedTotalAmount))")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.blue)
                                            .animation(.spring(response: 0.3), value: calculatedTotalAmount)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.03))
                                }
                            }
                            .background(Color.cardBackground(for: colorScheme))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 16)
                            
                            Spacer().frame(height: 16)
                            
                            // 🔖 Phase 1: 其他信息分组
                            VStack(spacing: 0) {
                                SectionHeader(title: L("manual.other_info"), icon: "ellipsis.circle.fill")
                                
                                Button(action: {
                                    notesFieldFocused = false
                                    currentEditingField = .parkingFee
                                    shouldClearOnNextInput = true
                                }) {
                                    DetailInputRow(
                                        icon: "parkingsign",
                                        title: L("manual.parking_fee"),
                                        value: formatValue(parkingFee, prefix: currencySymbol),
                                        hasArrow: false,
                                        isSelected: currentEditingField == .parkingFee,
                                        isEmpty: parkingFee.isEmpty || parkingFee == "0.00"
                                    )
                                }
                                
                                Button(action: {
                                    notesFieldFocused = false
                                    currentEditingField = .points
                                    shouldClearOnNextInput = true
                                }) {
                                    DetailInputRow(
                                        icon: "star.fill",
                                        title: L("manual.points"),
                                        value: points.isEmpty || points == "0" ? L("manual.not_entered") : points,
                                        hasArrow: false,
                                        isSelected: currentEditingField == .points,
                                        valueColor: .orange,
                                        isEmpty: points.isEmpty || points == "0"
                                    )
                                }
                                
                                // 极能抵扣（只读显示）
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.purple.opacity(0.15))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Text(L("manual.extreme_energy"))
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(formatExtremeEnergy(extremeEnergyKwh))
                                        .font(.system(size: 16))
                                        .foregroundColor(extremeEnergyKwh.isEmpty || extremeEnergyKwh == "0" ? .secondary.opacity(0.6) : .purple)
                                        .fontWeight(extremeEnergyKwh.isEmpty || extremeEnergyKwh == "0" ? .regular : .medium)
                                        .italic(extremeEnergyKwh.isEmpty || extremeEnergyKwh == "0")
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.cardBackground(for: colorScheme))
                                
                                // 备注输入行
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "note.text")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(L("manual.notes"))
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    TextField(L("text.click_to_input"), text: $notes)
                                        .font(.system(size: 16))
                                        .foregroundColor(notes.isEmpty ? .secondary : .primary)
                                        .multilineTextAlignment(.trailing)
                                        .focused($notesFieldFocused)
                                        .onChange(of: notesFieldFocused) { _, isFocused in
                                            if isFocused {
                                                currentEditingField = nil
                                            }
                                        }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.cardBackground(for: colorScheme))
                            }
                            .background(Color.cardBackground(for: colorScheme))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 16)
                            
                            Spacer().frame(height: 100)
                        }
                    }
                    
                    if shouldShowKeypad {
                        Spacer()
                        
                        // Phase 2: 数字键盘顶部提示
                        VStack(spacing: 0) {
                            // 当前编辑字段提示
                            if currentEditingField != nil {
                                HStack {
                                    Text(L("manual.editing") + ": \(displayDescription)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(displayAmount)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.05))
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
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
                                            currentEditingField = nil
                                        }
                                    }) {
                                        Text(L("text.done"))
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
                                        Text(L("common.save"))
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
            print("🔍 ManualInputView onAppear - editingRecord: \(editingRecord != nil), extractedData: \(extractedData != nil)")
            
            if let record = editingRecord {
                totalAmount = String(format: "%.2f", record.totalAmount)
                electricityAmount = String(format: "%.2f", record.amount)
                serviceFee = String(format: "%.2f", record.serviceFee)
                location = record.location
                electricityKwh = String(format: "%.1f", record.electricityAmount)
                chargingTime = record.chargingTime
                parkingFee = String(format: "%.2f", record.parkingFee)
                discountAmount = String(format: "%.2f", record.discountAmount)
                points = String(format: "%.0f", record.points)
                extremeEnergyKwh = String(format: "%.3f", record.extremeEnergyKwh)
                notes = record.notes
                selectedRecordType = record.recordType
            } else if let data = extractedData {
                print("📥 开始加载 extractedData")
                if !data.electricityAmount.isEmpty {
                    electricityAmount = data.electricityAmount
                }
                if !data.serviceFee.isEmpty {
                    serviceFee = data.serviceFee
                }
                if !data.electricityKwh.isEmpty {
                    electricityKwh = data.electricityKwh
                }
                if !data.location.isEmpty {
                    location = data.location
                } else if !categories.isEmpty {
                    location = categories.first?.name ?? ""
                }
                if !data.totalAmount.isEmpty && data.totalAmount != "0.00" {
                    totalAmount = data.totalAmount
                }
                if !data.discountAmount.isEmpty {
                    discountAmount = data.discountAmount
                    print("📝 加载优惠金额到输入界面: \(discountAmount)")
                }
                if !data.points.isEmpty {
                    points = data.points
                    print("📝 加载积分到输入界面: \(points)")
                }
                if !data.extremeEnergyKwh.isEmpty {
                    extremeEnergyKwh = data.extremeEnergyKwh
                    print("📝 加载极能抵扣到输入界面: \(extremeEnergyKwh) kWh")
                }
                if !data.notes.isEmpty {
                    notes = data.notes
                    print("📝 加载备注到输入界面: \(notes)")
                }
                print("🔍 检查 chargingTime: \(data.chargingTime != nil)")
                if let time = data.chargingTime {
                    chargingTime = time
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    print("✅ 成功加载充电时间到输入界面: \(formatter.string(from: time))")
                } else {
                    print("⚠️ extractedData.chargingTime 为 nil，使用默认当前时间")
                }
            } else if location.isEmpty && !categories.isEmpty {
                location = categories.first?.name ?? ""
            }
        }
    }
    
    // 计算属性：是否有输入值
    private var hasInputValue: Bool {
        (!electricityAmount.isEmpty && electricityAmount != "0.00") ||
        (!serviceFee.isEmpty && serviceFee != "0.00") ||
        (!discountAmount.isEmpty && discountAmount != "0.00")
    }
    
    // 计算属性：实付金额（自动计算）
    private var calculatedTotalAmount: Double {
        let electricity = Double(electricityAmount) ?? 0
        let service = Double(serviceFee) ?? 0
        let discount = Double(discountAmount) ?? 0
        return max(0, electricity + service - discount)
    }
    
    // 格式化值显示
    private func formatValue(_ value: String, prefix: String = "", suffix: String = "", defaultText: String = "") -> String {
        let defaultDisplay = defaultText.isEmpty ? L("text.not_entered") : defaultText
        if value.isEmpty || value == "0.00" || value == "0.0" || value == "0" {
            return defaultDisplay
        }
        return "\(prefix)\(value)\(suffix)"
    }
    
    // 格式化极能抵扣显示
    private func formatExtremeEnergy(_ value: String) -> String {
        if value.isEmpty || value == "0" || value == "0.0" || value == "0.00" || value == "0.000" {
            return L("manual.not_recognized")
        }
        // 格式化为3位小数并添加单位
        if let kwh = Double(value) {
            return String(format: "%.3f kWh", kwh)
        }
        return L("text.unrecognized")
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
        case .discountAmount:
            return discountAmount.isEmpty ? "0.00" : discountAmount
        case .points:
            return points.isEmpty ? "0" : points
        case .none:
            return "0.00"
        }
    }
    
    // 计算属性：显示描述
    private var displayDescription: String {
        switch currentEditingField {
        case .electricityAmount:
            return L("manual.electricity_fee")
        case .serviceFee:
            return L("manual.service_fee")
        case .electricityKwh:
            return L("manual.electricity_kwh")
        case .parkingFee:
            return L("manual.parking_fee")
        case .discountAmount:
            return L("manual.discount")
        case .points:
            return L("manual.points")
        case .none:
            return ""
        }
    }
    
    // 处理数字输入
    private func handleKeypadInput(_ digit: String) {
        if shouldClearOnNextInput {
            switch currentEditingField {
            case .electricityAmount:
                electricityAmount = ""
            case .serviceFee:
                serviceFee = ""
            case .electricityKwh:
                electricityKwh = ""
            case .parkingFee:
                parkingFee = ""
            case .discountAmount:
                discountAmount = ""
            case .points:
                points = ""
            case .none:
                break
            }
            shouldClearOnNextInput = false
        }
        
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
        case .discountAmount:
            if digit == "." && discountAmount.contains(".") { return }
            discountAmount += digit
        case .points:
            if digit != "." {
                points += digit
            }
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
        case .discountAmount:
            if !discountAmount.isEmpty {
                discountAmount.removeLast()
            }
        case .points:
            if !points.isEmpty {
                points.removeLast()
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
        let discount = Double(discountAmount) ?? 0
        let pointsValue = Double(points) ?? 0
        let total = calculatedTotalAmount
        let extremeEnergy = Double(extremeEnergyKwh) ?? 0
        
        if let record = editingRecord {
            record.location = location
            record.amount = electricity
            record.electricityAmount = kwh
            record.serviceFee = service
            record.totalAmount = total
            record.chargingTime = chargingTime
            record.parkingFee = parking
            record.discountAmount = discount
            record.points = pointsValue
            record.extremeEnergyKwh = extremeEnergy
            record.notes = notes
            record.recordType = selectedRecordType
            record.stationType = getStationType(from: location)
        } else {
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
                recordType: selectedRecordType,
                points: pointsValue,
                discountAmount: discount,
                extremeEnergyKwh: extremeEnergy
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
            let isChineseLanguage = Locale.current.language.languageCode?.identifier == "zh"
            formatter.dateFormat = isChineseLanguage ? "今天 HH:mm" : "'Today' HH:mm"
        } else if calendar.isDateInYesterday(date) {
            let isChineseLanguage = Locale.current.language.languageCode?.identifier == "zh"
            formatter.dateFormat = isChineseLanguage ? "昨天 HH:mm" : "'Yesterday' HH:mm"
        } else {
            let isChineseLanguage = Locale.current.language.languageCode?.identifier == "zh"
            formatter.dateFormat = isChineseLanguage ? "M月d日 HH:mm" : "MMM d HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - 分组标题组件
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - 公式项组件
struct FormulaItem: View {
    let label: String
    let value: String
    let symbol: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .foregroundColor(.secondary)
            Text("\(symbol)\(value.isEmpty ? "0" : value)")
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 输入行组件
struct DetailInputRow: View {
    let icon: String
    let title: String
    let value: String
    var hasArrow: Bool = false
    var hasCheckmark: Bool = false
    var hasX: Bool = false
    var isSelected: Bool = false
    var valueColor: Color = .secondary
    var isEmpty: Bool = false
    
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
                    .foregroundColor(isSelected ? .blue : (isEmpty ? .secondary.opacity(0.6) : valueColor))
                    .fontWeight(isSelected ? .semibold : (isEmpty ? .regular : .medium))
                    .italic(isEmpty)
                
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
                } else if isSelected {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 键盘按钮组件
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

// MARK: - 日期选择器
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
                DatePicker(L("text.select_time"), selection: $tempDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                
                Spacer()
            }
            .navigationTitle(L("manual.charging_time"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("text.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("manual.done")) {
                        selectedDate = tempDate
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 充电地点选择器
struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [ChargingStationCategory]
    @Binding var selectedLocation: String
    
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
            .navigationTitle(L("manual.charging_station"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("manual.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 记录类型按钮组件
struct RecordTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(width: 50, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ManualInputView()
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
