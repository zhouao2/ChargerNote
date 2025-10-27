//
//  DataManager.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import Foundation
import SwiftData
import SwiftUI

class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    // 获取本月支出
    func getMonthlyExpense(for date: Date = Date(), records: [ChargingRecord]) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        return records
            .filter { record in
                record.chargingTime >= startOfMonth && record.chargingTime < endOfMonth
            }
            .reduce(0) { $0 + $1.totalAmount }
    }
    
    // 获取本月充电度数
    func getMonthlyKwh(for date: Date = Date(), records: [ChargingRecord]) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        return records
            .filter { record in
                record.chargingTime >= startOfMonth && record.chargingTime < endOfMonth
            }
            .reduce(0) { $0 + $1.electricityAmount }
    }
    
    // 获取月度统计数据
    func getMonthlyStatistics(_ records: [ChargingRecord], for date: Date) -> MonthlyStatistics {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        let monthRecords = records.filter { record in
            record.chargingTime >= startOfMonth && record.chargingTime < endOfMonth
        }
        
        let totalExpense = monthRecords.reduce(0) { $0 + $1.totalAmount }
        let count = monthRecords.count
        let totalKwh = monthRecords.reduce(0) { $0 + $1.electricityAmount }
        let averageKwh = count > 0 ? totalKwh / Double(count) : 0
        
        return MonthlyStatistics(
            totalExpense: totalExpense,
            count: count,
            averageKwh: averageKwh
        )
    }
    
    // 获取按日期分组的记录（用于历史页面时间轴）
    func getRecordsGroupedByDate(_ records: [ChargingRecord], for date: Date) -> [TimelineDayData] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        // 筛选当月记录
        let monthRecords = records.filter { record in
            record.chargingTime >= startOfMonth && record.chargingTime < endOfMonth
        }
        
        // 按日期分组
        let grouped = Dictionary(grouping: monthRecords) { record -> String in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: record.chargingTime)
        }
        
        // 转换为TimelineDayData数组
        var timelineData: [TimelineDayData] = []
        
        for (dateString, dayRecords) in grouped {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateFormatter.date(from: dateString) else { continue }
            
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "M月d日 EEEE"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            let displayDate = displayFormatter.string(from: date)
                .replacingOccurrences(of: "Monday", with: "周一")
                .replacingOccurrences(of: "Tuesday", with: "周二")
                .replacingOccurrences(of: "Wednesday", with: "周三")
                .replacingOccurrences(of: "Thursday", with: "周四")
                .replacingOccurrences(of: "Friday", with: "周五")
                .replacingOccurrences(of: "Saturday", with: "周六")
                .replacingOccurrences(of: "Sunday", with: "周日")
            
            let totalAmount = dayRecords.reduce(0) { $0 + $1.totalAmount }
            let sortedRecords = dayRecords.sorted { $0.chargingTime > $1.chargingTime }
            
            timelineData.append(TimelineDayData(
                date: displayDate,
                totalAmount: totalAmount,
                records: sortedRecords
            ))
        }
        
        // 按日期降序排序
        return timelineData.sorted { data1, data2 in
            guard let date1 = parseDate(from: data1.date),
                  let date2 = parseDate(from: data2.date) else {
                return false
            }
            return date1 > date2
        }
    }
    
    private func parseDate(from displayString: String) -> Date? {
        // 从 "1月15日 周一" 格式提取日期
        let components = displayString.components(separatedBy: " ")
        guard let dateComponent = components.first else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        
        return formatter.date(from: dateComponent)
    }
    
    // 获取今日记录
    func getTodayRecords(_ records: [ChargingRecord]) -> [ChargingRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        return records
            .filter { record in
                record.chargingTime >= today && record.chargingTime < tomorrow
            }
            .sorted { $0.chargingTime > $1.chargingTime }
    }
    
    
    // 获取按地点分组的统计数据
    func getLocationStatistics(_ records: [ChargingRecord], categories: [ChargingStationCategory]) -> [LocationStatistics] {
        let grouped = Dictionary(grouping: records) { $0.location }
        
        return grouped.map { (location, records) in
            let totalAmount = records.reduce(0) { $0 + $1.totalAmount }
            let count = records.count
            let category = categories.first { $0.name == location }
            return LocationStatistics(
                stationType: location,
                count: count,
                totalAmount: totalAmount,
                color: category != nil ? Color(hex: category!.color) : .gray
            )
        }.sorted { $0.totalAmount > $1.totalAmount }
    }
    
    // 根据时间范围获取趋势数据
    func getTrendData(_ records: [ChargingRecord], timeRange: TimeRange) -> [TrendDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var trendData: [TrendDataPoint] = []
        
        switch timeRange {
        case .week:
            // 显示最近7天，每天一个点
            for i in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                
                let dayRecords = records.filter { record in
                    record.chargingTime >= date && record.chargingTime < nextDay
                }
                
                let totalAmount = dayRecords.reduce(0) { $0 + $1.totalAmount }
                let label = formatDateLabel(date, format: "E")  // 周几
                
                trendData.append(TrendDataPoint(
                    date: date,
                    label: label,
                    amount: totalAmount
                ))
            }
            
        case .month:
            // 显示最近4周，每周一个点
            for i in (0..<4).reversed() {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) else { continue }
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                
                let weekRecords = records.filter { record in
                    record.chargingTime >= weekStart && record.chargingTime < weekEnd
                }
                
                let totalAmount = weekRecords.reduce(0) { $0 + $1.totalAmount }
                let label = "第\(4-i)周"
                
                trendData.append(TrendDataPoint(
                    date: weekStart,
                    label: label,
                    amount: totalAmount
                ))
            }
            
        case .year:
            // 显示最近12个月，每月一个点
            for i in (0..<12).reversed() {
                guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
                let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
                
                let monthRecords = records.filter { record in
                    guard let start = monthInterval?.start, let end = monthInterval?.end else { return false }
                    return record.chargingTime >= start && record.chargingTime < end
                }
                
                let totalAmount = monthRecords.reduce(0) { $0 + $1.totalAmount }
                let label = formatDateLabel(monthStart, format: "M月")
                
                trendData.append(TrendDataPoint(
                    date: monthStart,
                    label: label,
                    amount: totalAmount
                ))
            }
        }
        
        return trendData
    }
    
    private func formatDateLabel(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func getColorForStationType(_ stationType: String) -> Color {
        switch stationType {
        case "极氪": return .black
        case "特斯拉": return .orange
        case "小鹏": return .blue
        case "蔚来": return .green
        case "国家电网": return .purple
        default: return .gray
        }
    }
    
    private func getDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        
        let dayNames = ["Sunday": "周日", "Monday": "周一", "Tuesday": "周二", 
                       "Wednesday": "周三", "Thursday": "周四", "Friday": "周五", "Saturday": "周六"]
        
        let englishDay = formatter.string(from: date)
        return dayNames[englishDay] ?? "未知"
    }
}

struct LocationStatistics {
    let stationType: String
    let count: Int
    let totalAmount: Double
    let color: Color
}

struct DailyExpense: Identifiable {
    let id = UUID()
    let day: String
    let amount: Double
    let height: CGFloat
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let amount: Double
}

enum TimeRange: String, CaseIterable {
    case week = "周"
    case month = "月"
    case year = "年"
}

struct MonthlyStatistics {
    let totalExpense: Double
    let count: Int
    let averageKwh: Double
}

struct TimelineDayData: Identifiable {
    let id = UUID()
    let date: String
    let totalAmount: Double
    let records: [ChargingRecord]
}
