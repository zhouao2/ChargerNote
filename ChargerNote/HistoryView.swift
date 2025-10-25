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
                                gradient: Gradient(colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.19, green: 0.69, blue: 0.31)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .overlay(
                                VStack(spacing: 16) {
                                    // 标题和搜索
                                    HStack {
                                        Text("历史记录")
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
                                        Text("\(monthYearFormatter.string(from: selectedMonth))统计")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(monthStats.count)条记录")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        StatisticItem(title: "总支出", value: "\(currencySymbol)\(String(format: "%.0f", monthStats.totalExpense))", color: .primary)
                                        StatisticItem(title: "充电次数", value: "\(monthStats.count)", color: .primary)
                                        StatisticItem(title: "平均度数", value: String(format: "%.1f", monthStats.averageKwh), color: .primary)
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 日期标题
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.19, green: 0.69, blue: 0.31)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
    
    private let actionButtonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = 50
    
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 前景内容 - 覆盖整个区域
                HistoryRecordRow(record: record, currencySymbol: currencySymbol)
                    .frame(width: geometry.size.width)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .offset(x: offset)
                    .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let translation = gesture.translation.width
                            if translation < 0 {
                                // 向左滑动
                                offset = max(translation, -(actionButtonWidth * 2))
                            } else if offset < 0 {
                                // 向右滑动恢复
                                offset = min(0, offset + translation)
                            }
                        }
                        .onEnded { gesture in
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
                )
            }
        }
        .frame(height: 72)
    }
}

struct HistoryRecordRow: View {
    let record: ChargingRecord
    let currencySymbol: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(record.location)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(formatTime(record.chargingTime)) • \(String(format: "%.1f", record.electricityAmount))度电")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 金额
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currencySymbol)\(String(format: "%.2f", record.totalAmount))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(record.serviceFee > 0 ? "服务费\(currencySymbol)\(String(format: "%.0f", record.serviceFee))" : "无服务费")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
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
