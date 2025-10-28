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
            // 显示本周（周一到周日），每天一个点
            // 获取本周周一
            var startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now)
            startOfWeek.weekday = 2 // 周一
            guard let mondayDate = calendar.date(from: startOfWeek) else { return [] }
            
            // 从周一循环到周日（7天）
            for i in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: i, to: mondayDate) else { continue }
                let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                
                let dayRecords = records.filter { record in
                    record.chargingTime >= date && record.chargingTime < nextDay && record.recordType == "充电"
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
            // 显示本月按周聚合的数据（从1号开始，每7天一组）
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            
            // 最多显示5周（1-7, 8-14, 15-21, 22-28, 29-31）
            for weekIndex in 0..<5 {
                let weekStartDay = weekIndex * 7 + 1
                var weekStartComponents = calendar.dateComponents([.year, .month], from: startOfMonth)
                weekStartComponents.day = weekStartDay
                
                guard let weekStart = calendar.date(from: weekStartComponents) else { continue }
                
                // 如果周开始日期超过了今天或超出本月，则停止
                if weekStart > now || !calendar.isDate(weekStart, equalTo: startOfMonth, toGranularity: .month) {
                    break
                }
                
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                
                // 过滤这一周的记录（只统计到今天为止，且不超出本月，仅统计充电记录）
                let weekRecords = records.filter { record in
                    record.chargingTime >= weekStart && 
                    record.chargingTime < min(weekEnd, calendar.date(byAdding: .day, value: 1, to: now) ?? now) &&
                    calendar.isDate(record.chargingTime, equalTo: startOfMonth, toGranularity: .month) &&
                    record.recordType == "充电"
                }
                
                let totalAmount = weekRecords.reduce(0) { $0 + $1.totalAmount }
                let label = "第\(weekIndex + 1)周"
                
                trendData.append(TrendDataPoint(
                    date: weekStart,
                    label: label,
                    amount: totalAmount
                ))
            }
            
        case .year:
            // 显示本年度（1-12月），每月一个点
            // 获取本年1月1日
            let year = calendar.component(.year, from: now)
            var januaryComponents = DateComponents()
            januaryComponents.year = year
            januaryComponents.month = 1
            januaryComponents.day = 1
            guard let januaryDate = calendar.date(from: januaryComponents) else { return [] }
            
            // 从1月循环到12月
            for monthOffset in 0..<12 {
                guard let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: januaryDate) else { continue }
                let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
                
                let monthRecords = records.filter { record in
                    guard let start = monthInterval?.start, let end = monthInterval?.end else { return false }
                    return record.chargingTime >= start && record.chargingTime < end && record.recordType == "充电"
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
    
    // 根据时间范围获取充电度数趋势数据
    func getElectricityTrendData(_ records: [ChargingRecord], timeRange: TimeRange) -> [TrendDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var trendData: [TrendDataPoint] = []
        
        switch timeRange {
        case .week:
            // 显示本周（周一到周日），每天一个点
            // 获取本周周一
            var startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now)
            startOfWeek.weekday = 2 // 周一
            guard let mondayDate = calendar.date(from: startOfWeek) else { return [] }
            
            // 从周一循环到周日（7天）
            for i in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: i, to: mondayDate) else { continue }
                let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                
                let dayRecords = records.filter { record in
                    record.chargingTime >= date && record.chargingTime < nextDay && record.recordType == "充电"
                }
                
                let totalKwh = dayRecords.reduce(0) { $0 + $1.electricityAmount }
                let label = formatDateLabel(date, format: "E")  // 周几
                
                trendData.append(TrendDataPoint(
                    date: date,
                    label: label,
                    amount: totalKwh
                ))
            }
            
        case .month:
            // 显示本月按周聚合的数据（从1号开始，每7天一组）
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            
            // 最多显示5周（1-7, 8-14, 15-21, 22-28, 29-31）
            for weekIndex in 0..<5 {
                let weekStartDay = weekIndex * 7 + 1
                var weekStartComponents = calendar.dateComponents([.year, .month], from: startOfMonth)
                weekStartComponents.day = weekStartDay
                
                guard let weekStart = calendar.date(from: weekStartComponents) else { continue }
                
                // 如果周开始日期超过了今天或超出本月，则停止
                if weekStart > now || !calendar.isDate(weekStart, equalTo: startOfMonth, toGranularity: .month) {
                    break
                }
                
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                
                // 过滤这一周的记录（只统计到今天为止，且不超出本月，仅统计充电记录）
                let weekRecords = records.filter { record in
                    record.chargingTime >= weekStart && 
                    record.chargingTime < min(weekEnd, calendar.date(byAdding: .day, value: 1, to: now) ?? now) &&
                    calendar.isDate(record.chargingTime, equalTo: startOfMonth, toGranularity: .month) &&
                    record.recordType == "充电"
                }
                
                let totalKwh = weekRecords.reduce(0) { $0 + $1.electricityAmount }
                let label = "第\(weekIndex + 1)周"
                
                trendData.append(TrendDataPoint(
                    date: weekStart,
                    label: label,
                    amount: totalKwh
                ))
            }
            
        case .year:
            // 显示本年度（1-12月），每月一个点
            // 获取本年1月1日
            let year = calendar.component(.year, from: now)
            var januaryComponents = DateComponents()
            januaryComponents.year = year
            januaryComponents.month = 1
            januaryComponents.day = 1
            guard let januaryDate = calendar.date(from: januaryComponents) else { return [] }
            
            // 从1月循环到12月
            for monthOffset in 0..<12 {
                guard let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: januaryDate) else { continue }
                let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
                
                let monthRecords = records.filter { record in
                    guard let start = monthInterval?.start, let end = monthInterval?.end else { return false }
                    return record.chargingTime >= start && record.chargingTime < end && record.recordType == "充电"
                }
                
                let totalKwh = monthRecords.reduce(0) { $0 + $1.electricityAmount }
                let label = formatDateLabel(monthStart, format: "M月")
                
                trendData.append(TrendDataPoint(
                    date: monthStart,
                    label: label,
                    amount: totalKwh
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
