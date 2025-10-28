//
//  HistoryView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var chargingRecords: [ChargingRecord]
    @Query private var userSettings: [UserSettings]
    @State private var selectedMonth = Date()
    @State private var editingRecord: ChargingRecord?
    private let dataManager = DataManager.shared
    
    private var currencySymbol: String {
        userSettings.first?.currencySymbol ?? "¥"
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
                                    // 标题和搜索
                                    HStack {
                                        Text(L("history.title"))
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                    
                                    // 日期选择器
                                    HStack {
                                        HStack(spacing: 12) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text(monthYearFormatter.string(from: selectedMonth))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 8) {
                                            Button(action: previousMonth) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.2))
                                                        .frame(width: 32, height: 32)
                                                    Image(systemName: "chevron.left")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            
                                            Button(action: nextMonth) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.2))
                                                        .frame(width: 32, height: 32)
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    .padding(.horizontal, 24)
                                }
                            )
                            
                            // 白色内容区域
                            VStack(spacing: 24) {
                                // 月度统计卡片
                                let monthStats = dataManager.getMonthlyStatistics(chargingRecords, for: selectedMonth)
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("\(monthYearFormatter.string(from: selectedMonth))" + L("history.statistics"))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(monthStats.count)" + L("history.records_count"))
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        StatisticItem(title: L("history.total_expense"), value: "\(currencySymbol)\(String(format: "%.0f", monthStats.totalExpense))", color: .primary)
                                        StatisticItem(title: L("analytics.charging_times"), value: "\(monthStats.count)", color: .primary)
                                        StatisticItem(title: L("history.avg_kwh"), value: String(format: "%.1f", monthStats.averageKwh), color: .primary)
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.cardBackground(for: colorScheme))
                                        .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
                                )
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                
                                // 时间轴记录
                                VStack(spacing: 24) {
                                    ForEach(timelineData, id: \.date) { dayData in
                                        TimelineDayView(dayData: dayData, currencySymbol: currencySymbol, onEdit: { record in
                                            editingRecord = record
                                        }, onDelete: { record in
                                            deleteRecord(record)
                                        })
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.bottom, 100) // 为底部导航留出空间
                        }
                    }
                }
            }
        }
        .sheet(item: $editingRecord) { record in
            ManualInputView(editingRecord: record)
        }
    }
    
    // 获取时间轴数据
    private var timelineData: [TimelineDayData] {
        dataManager.getRecordsGroupedByDate(chargingRecords, for: selectedMonth)
    }
    
    private func deleteRecord(_ record: ChargingRecord) {
        modelContext.delete(record)
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }
    
    private func previousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimelineDayView: View {
    let dayData: TimelineDayData
    let currencySymbol: String
    let onEdit: (ChargingRecord) -> Void
    let onDelete: (ChargingRecord) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 日期标题
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.adaptiveGreenBorder(for: colorScheme))
                        .frame(width: 12, height: 12)
                }
                
                Text(dayData.date)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(currencySymbol)\(String(format: "%.2f", dayData.totalAmount))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 0)
            
            // 记录列表
            VStack(spacing: 12) {
                ForEach(dayData.records, id: \.id) { record in
                    SwipeableRecordRow(record: record, currencySymbol: currencySymbol, onEdit: {
                        onEdit(record)
                    }, onDelete: {
                        onDelete(record)
                    })
                }
            }
        }
    }
}

// 可左滑的记录行组件
struct SwipeableRecordRow: View {
    let record: ChargingRecord
    let currencySymbol: String
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
                        Text(L("common.edit"))
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
                        Text(L("common.delete"))
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 前景内容 - 覆盖整个区域
                HistoryRecordRow(record: record, currencySymbol: currencySymbol)
                    .frame(width: geometry.size.width)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground(for: colorScheme))
                            .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                                // 判断滑动方向（仅在首次滑动时判断）
                                if dragDirection == nil {
                                    let horizontalAmount = abs(gesture.translation.width)
                                    let verticalAmount = abs(gesture.translation.height)
                                    
                                    // 增加判断的严格度：水平位移必须明显大于垂直位移
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
                                        // 向左滑动
                                        offset = max(translation, -(actionButtonWidth * 2))
                                    } else if offset < 0 {
                                        // 向右滑动恢复
                                        offset = min(0, offset + translation)
                                    }
                                }
                            }
                            .onEnded { gesture in
                                // 重置方向判断
                                dragDirection = nil
                                
                                // 只有在水平滑动时才处理结束状态
                                let horizontalAmount = abs(gesture.translation.width)
                                let verticalAmount = abs(gesture.translation.height)
                                
                                if horizontalAmount > verticalAmount * 1.5 {
                                    let translation = gesture.translation.width
                                    withAnimation(.spring()) {
                                        if translation < -swipeThreshold && offset > -(actionButtonWidth * 2) {
                                            // 滑动超过阈值，显示按钮
                                            offset = -(actionButtonWidth * 2)
                                        } else if translation > swipeThreshold && offset < 0 {
                                            // 滑动超过阈值，隐藏按钮
                                            offset = 0
                                        } else if offset < -(actionButtonWidth) {
                                            // 已经显示，保持显示
                                            offset = -(actionButtonWidth * 2)
                                        } else {
                                            // 未达到阈值，恢复原位
                                            offset = 0
                                        }
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 72)
    }
}

struct HistoryRecordRow: View {
    let record: ChargingRecord
    let currencySymbol: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标 - 根据记录类型显示不同图标
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                Image(systemName: recordTypeIcon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.location)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // 记录类型标签（非充电时显示）
                    if record.recordType != "充电" {
                        Text(record.recordType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(recordTypeLabelColor)
                            )
                    }
                }
                
                // 第二行信息 - 根据记录类型显示不同内容
                if record.recordType == "充值" {
                    Text("\(formatTime(record.chargingTime)) • " + L("history.acquired") + String(format: "%.1f", record.electricityAmount) + L("history.kwh"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(formatTime(record.chargingTime)) • \(String(format: "%.1f", record.electricityAmount))" + L("history.kwh_unit"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 金额 - 根据记录类型显示不同颜色和信息
            VStack(alignment: .trailing, spacing: 4) {
                if record.recordType == "充值" {
                    // 充值显示为绿色
                    Text("+\(currencySymbol)\(String(format: "%.2f", record.amount))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    // 其他类型显示为常规色
                    Text("\(currencySymbol)\(String(format: "%.2f", record.totalAmount))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                // 第二行金额信息
                if record.recordType == "充值" {
                    // 充值显示度数/元比例
                    if record.amount > 0 {
                        Text("约\(currencySymbol)\(String(format: "%.2f", record.amount / record.electricityAmount))/度")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(record.serviceFee > 0 ? "服务费\(currencySymbol)\(String(format: "%.0f", record.serviceFee))" : "无服务费")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
        )
    }
    
    // 根据记录类型返回对应图标
    private var recordTypeIcon: String {
        switch record.recordType {
        case "充值":
            return "creditcard.fill"
        case "换电":
            return "arrow.triangle.2.circlepath"
        case "维修":
            return "wrench.fill"
        default: // "充电"
            return "bolt.circle.fill"
        }
    }
    
    // 记录类型标签颜色
    private var recordTypeLabelColor: Color {
        switch record.recordType {
        case "充值":
            return .green
        case "换电":
            return .orange
        case "维修":
            return .red
        default:
            return .blue
        }
    }
    
    private var iconBackgroundColor: Color {
        switch record.stationType {
        case "特斯拉":
            return Color.orange.opacity(0.1)
        case "小鹏":
            return Color.blue.opacity(0.1)
        case "蔚来":
            return Color.green.opacity(0.1)
        default:
            return Color.purple.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        switch record.stationType {
        case "特斯拉":
            return .orange
        case "小鹏":
            return .blue
        case "蔚来":
            return .green
        default:
            return .purple
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
