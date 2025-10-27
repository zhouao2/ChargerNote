//
//  AnalyticsView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chargingRecords: [ChargingRecord]
    @Query private var categories: [ChargingStationCategory]
    @Query private var userSettings: [UserSettings]
    @State private var selectedTimeRange: TimeRange = .month
    private let dataManager = DataManager.shared
    
    private var currencySymbol: String {
        userSettings.first?.currencySymbol ?? "¥"
    }
    
    
    // 根据选择的时间范围过滤记录
    private var filteredRecords: [ChargingRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return chargingRecords.filter { $0.chargingTime >= startOfMonth && $0.chargingTime < endOfMonth }
            
        case .quarter:
            let currentMonth = calendar.component(.month, from: now)
            let quarterStartMonth = ((currentMonth - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            components.day = 1
            let startOfQuarter = calendar.date(from: components) ?? now
            let endOfQuarter = calendar.date(byAdding: .month, value: 3, to: startOfQuarter) ?? now
            return chargingRecords.filter { $0.chargingTime >= startOfQuarter && $0.chargingTime < endOfQuarter }
            
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return chargingRecords.filter { $0.chargingTime >= startOfYear && $0.chargingTime < endOfYear }
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
                                gradient: Gradient(colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.19, green: 0.69, blue: 0.31)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .overlay(
                                VStack(spacing: 16) {
                                    // 标题和下载
                                    HStack {
                                        Text("统计分析")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                    
                                    // 时间维度切换
                                    HStack(spacing: 1) {
                                        ForEach(TimeRange.allCases, id: \.self) { range in
                                            Button(action: {
                                                selectedTimeRange = range
                                            }) {
                                                Text(range.rawValue)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(selectedTimeRange == range ? .green : .white.opacity(0.8))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(selectedTimeRange == range ? Color.white : Color.clear)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    .padding(.horizontal, 24)
                                }
                            )
                            
                            // 白色内容区域
                            VStack(spacing: 24) {
                                // 支出统计卡片
                                HStack(spacing: 16) {
                                    StatisticCard(
                                        title: selectedTimeRange == .month ? "本月支出" : selectedTimeRange == .quarter ? "本季支出" : "本年支出",
                                        value: "\(currencySymbol)\(String(format: "%.0f", filteredRecords.reduce(0) { $0 + $1.totalAmount }))",
                                        change: selectedTimeRange.rawValue,
                                        changeColor: .green,
                                        icon: "arrow.up"
                                    )
                                    
                                    StatisticCard(
                                        title: "充电次数",
                                        value: "\(filteredRecords.count)",
                                        change: "总计",
                                        changeColor: .blue,
                                        icon: "bolt.circle"
                                    )
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                
                                // 趋势图
                                TrendChartView(
                                    dataPoints: dataManager.getTrendData(filteredRecords, timeRange: selectedTimeRange),
                                    timeRange: selectedTimeRange,
                                    currencySymbol: currencySymbol
                                )
                                .padding(.horizontal, 24)
                                
                                // 地点分布图
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("地点分布")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("按消费金额")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 16) {
                                        ForEach(dataManager.getLocationStatistics(filteredRecords, categories: categories), id: \.stationType) { location in
                                            LocationDistributionRow(location: location, currencySymbol: currencySymbol)
                                        }
                                    }
                                }
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                                )
                                .padding(.horizontal, 24)
                            }
                            .padding(.bottom, 100) // 为底部导航留出空间
                        }
                    }
                }
            }
        }
    }
    
}

struct ChartData: Identifiable {
    let id = UUID()
    let day: String
    let height: CGFloat
    let value: Double
}


struct StatisticCard: View {
    let title: String
    let value: String
    let change: String
    let changeColor: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(changeColor)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(change)
                .font(.system(size: 14))
                .foregroundColor(changeColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
}

struct LocationDistributionRow: View {
    let location: LocationStatistics
    let currencySymbol: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(location.color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(location.color)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(location.stationType)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(location.count)次充电")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 金额和进度条
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(currencySymbol)\(String(format: "%.2f", location.totalAmount))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 64, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(location.color)
                        .frame(width: 64, height: 8)
                }
            }
        }
    }
}

// 折线图组件
struct TrendChartView: View {
    let dataPoints: [TrendDataPoint]
    let timeRange: TimeRange
    let currencySymbol: String
    
    private var maxAmount: Double {
        dataPoints.map { $0.amount }.max() ?? 100
    }
    
    private var displayInterval: Int {
        switch timeRange {
        case .month: return 5  // 每5天显示一个标签
        case .quarter: return 2 // 每2周显示一个标签
        case .year: return 2    // 每2个月显示一个标签
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("支出趋势")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(timeRangeDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            if dataPoints.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("暂无数据")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else {
                // 折线图
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        // 背景网格线
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                HStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 1)
                                }
                                if i < 4 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // 折线图路径
                        Path { path in
                            let chartWidth = geometry.size.width
                            let chartHeight = geometry.size.height - 40 // 留出底部标签空间
                            let stepX = chartWidth / CGFloat(max(dataPoints.count - 1, 1))
                            
                            for (index, point) in dataPoints.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalizedAmount = maxAmount > 0 ? point.amount / maxAmount : 0
                                let y = chartHeight * (1 - CGFloat(normalizedAmount))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.19, green: 0.69, blue: 0.31)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        
                        // 渐变填充
                        Path { path in
                            let chartWidth = geometry.size.width
                            let chartHeight = geometry.size.height - 40
                            let stepX = chartWidth / CGFloat(max(dataPoints.count - 1, 1))
                            
                            for (index, point) in dataPoints.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalizedAmount = maxAmount > 0 ? point.amount / maxAmount : 0
                                let y = chartHeight * (1 - CGFloat(normalizedAmount))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: chartHeight))
                                    path.addLine(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            
                            path.addLine(to: CGPoint(x: chartWidth, y: chartHeight))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.3),
                                    Color(red: 0.19, green: 0.69, blue: 0.31).opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // 数据点
                        ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                            let chartWidth = geometry.size.width
                            let chartHeight = geometry.size.height - 40
                            let stepX = chartWidth / CGFloat(max(dataPoints.count - 1, 1))
                            let x = CGFloat(index) * stepX
                            let normalizedAmount = maxAmount > 0 ? point.amount / maxAmount : 0
                            let y = chartHeight * (1 - CGFloat(normalizedAmount))
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 0.2, green: 0.78, blue: 0.35), lineWidth: 2)
                                )
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 200)
                
                // X轴标签
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                        if index % displayInterval == 0 || index == dataPoints.count - 1 {
                            Text(point.label)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private var timeRangeDescription: String {
        switch timeRange {
        case .month: return "最近30天"
        case .quarter: return "最近12周"
        case .year: return "最近12个月"
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
