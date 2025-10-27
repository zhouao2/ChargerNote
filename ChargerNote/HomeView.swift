//
//  HomeView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit
import Vision
import VisionKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var chargingRecords: [ChargingRecord]
    @Query private var userSettings: [UserSettings]
    @Query(sort: \ChargingStationCategory.sortOrder) private var categories: [ChargingStationCategory]
    @State private var showingManualInput = false
    @State private var editingRecord: ChargingRecord?
    @State private var showingImagePicker = false
    @State private var extractedData: ExtractedChargingData?
    @State private var isProcessingImage = false
    @State private var processingStatus: String = "正在识别充电信息"
    @State private var showingNewStationAlert = false
    @State private var recognizedStationName: String = ""
    private let dataManager = DataManager.shared
    
    private var currencySymbol: String {
        userSettings.first?.currencySymbol ?? "¥"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部导航区域
                        VStack(spacing: 0) {
                            // 主要内容区域
                            VStack(spacing: 0) {
                                // 绿色渐变背景
                                LinearGradient(
                                    gradient: Gradient(colors: Color.adaptiveGreenColors(for: colorScheme)),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 16) {
                                        // 标题和通知
                                        HStack {
                                            Text("充电记账")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "bell")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.top, 20)
                                        
                                        // 本月支出卡片
                                        HStack(spacing: 0) {
                                            // 左侧：本月支出
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("本月支出")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Text("\(currencySymbol)\(String(format: "%.2f", dataManager.getMonthlyExpense(for: Date(), records: chargingRecords)))")
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(20)
                                            
                                            // 分隔线
                                            Rectangle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: 1)
                                                .padding(.vertical, 16)
                                            
                                            // 右侧：本月充电度数
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("本月度数")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Text("\(String(format: "%.1f", dataManager.getMonthlyKwh(for: Date(), records: chargingRecords))) kWh")
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(20)
                                        }
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.2))
                                        )
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 16)
                                    }
                                )
                                
                                // 白色内容区域
                                VStack(spacing: 24) {
                                    // 操作按钮区域
                                    HStack(spacing: 16) {
                                        // 上传截图按钮
                                        Button(action: {
                                            showingImagePicker = true
                                        }) {
                                            VStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.1))
                                                        .frame(width: 64, height: 64)
                                                    Image(systemName: "camera")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.blue)
                                                }
                                                
                                                VStack(spacing: 4) {
                                                    Text("上传截图")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    Text("自动识别费用")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(24)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.cardBackground(for: colorScheme))
                                                    .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        // 手动输入按钮
                                        Button(action: {
                                            showingManualInput = true
                                        }) {
                                            VStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.green.opacity(0.1))
                                                        .frame(width: 64, height: 64)
                                                    Image(systemName: "pencil")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.green)
                                                }
                                                
                                                VStack(spacing: 4) {
                                                    Text("手动输入")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    Text("快速记录费用")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(24)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.cardBackground(for: colorScheme))
                                                    .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 24)
                                    
                                    // 今日记录
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("今日记录")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text("\(dataManager.getTodayRecords(chargingRecords).count)条记录")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 24)
                                        
                                        // 记录列表
                                        VStack(spacing: 12) {
                                            ForEach(dataManager.getTodayRecords(chargingRecords), id: \.id) { record in
                                                SwipeableHomeRecordRow(record: record, currencySymbol: currencySymbol, onEdit: {
                                                    editingRecord = record
                                                }, onDelete: {
                                                    deleteRecord(record)
                                                })
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                                .padding(.bottom, 100) // 为底部导航留出空间
                            }
                        }
                    }
                }
                
                // OCR 识别进度指示器
                if isProcessingImage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            // 加载动画
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            // 进度文字
                            VStack(spacing: 8) {
                                Text(processingStatus)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("请稍候...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                    .transition(.opacity)
                }
            }
        }
        .sheet(isPresented: $showingManualInput, onDismiss: {
            extractedData = nil
        }) {
            if let data = extractedData {
                ManualInputView(extractedData: data)
            } else {
                ManualInputView()
            }
        }
        .sheet(item: $editingRecord) { record in
            ManualInputView(editingRecord: record)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(onImageSelected: { image in
                processImage(image)
            })
        }
        .alert("识别到新站点", isPresented: $showingNewStationAlert) {
            Button("创建站点") {
                createNewStation(name: recognizedStationName)
                showingManualInput = true
            }
            Button("使用现有站点") {
                // 清除识别到的站点名称，让用户手动选择
                if let data = extractedData {
                    extractedData = ExtractedChargingData(
                        electricityAmount: data.electricityAmount,
                        serviceFee: data.serviceFee,
                        electricityKwh: data.electricityKwh,
                        location: "",
                        totalAmount: data.totalAmount,
                        points: data.points,
                        notes: data.notes,
                        chargingTime: data.chargingTime
                    )
                }
                showingManualInput = true
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("识别到充电站点「\(recognizedStationName)」，但该站点尚未添加到系统中。是否创建新站点？")
        }
    }
    
    private func deleteRecord(_ record: ChargingRecord) {
        modelContext.delete(record)
    }
    
    // 创建新充电站点
    private func createNewStation(name: String) {
        // 根据站点名称选择颜色和图标
        var color = "#007AFF"
        var icon = "bolt.circle.fill"
        
        if name.contains("特斯拉") || name.contains("Tesla") {
            color = "#FF9500"
            icon = "bolt.circle.fill"
        } else if name.contains("小鹏") || name.contains("XPENG") {
            color = "#007AFF"
            icon = "bolt.circle.fill"
        } else if name.contains("蔚来") || name.contains("NIO") {
            color = "#34C759"
            icon = "bolt.circle.fill"
        } else if name.contains("国家电网") || name.contains("国网") {
            color = "#AF52DE"
            icon = "bolt.circle.fill"
        }
        
        // 获取当前最大的 sortOrder
        let maxSortOrder = categories.map { $0.sortOrder }.max() ?? 0
        
        let newCategory = ChargingStationCategory(
            name: name,
            color: color,
            icon: icon,
            sortOrder: maxSortOrder + 1
        )
        
        modelContext.insert(newCategory)
        print("创建新站点: \(name)")
    }
    
    // 处理图片并进行 OCR 识别
    private func processImage(_ image: UIImage) {
        withAnimation {
            isProcessingImage = true
            processingStatus = "正在加载图片"
        }
        
        guard let cgImage = image.cgImage else {
            withAnimation {
                isProcessingImage = false
            }
            return
        }
        
        // 延迟一下，让用户看到状态更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                processingStatus = "正在识别文字"
            }
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.isProcessingImage = false
                    }
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isProcessingImage = false
                    }
                }
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            print("识别的文本：\n\(recognizedText)")
            
            DispatchQueue.main.async {
                withAnimation {
                    self.processingStatus = "正在提取充电信息"
                }
                
                // 延迟一下让用户看到状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.extractDataFromText(recognizedText)
                    withAnimation {
                        self.isProcessingImage = false
                    }
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("OCR 识别失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.isProcessingImage = false
                    }
                }
            }
        }
    }
    
    // 从识别的文字中提取充电数据
    private func extractDataFromText(_ text: String) {
        var electricityAmount: String = ""
        var serviceFee: String = ""
        var electricityKwh: String = ""
        var location: String = ""
        var totalAmount: String = ""
        var points: String = ""
        var pointsDiscount: String = ""
        var couponDiscount: String = ""
        var energyDiscount: String = ""
        var noteItems: [String] = []
        var chargingTime: Date?
        
        let lines = text.components(separatedBy: .newlines)
        
        // 充电站品牌关键词映射
        let stationKeywords: [(keywords: [String], name: String)] = [
            (["特斯拉", "Tesla", "TESLA"], "特斯拉充电站"),
            (["小鹏", "XPENG", "Xpeng", "小鹏汽车"], "小鹏充电站"),
            (["蔚来", "NIO", "Nio"], "蔚来充电站"),
            (["国家电网", "国网", "State Grid"], "国家电网"),
            (["星星充电", "万马", "万马充电"], "星星充电"),
            (["云快充", "云快"], "云快充"),
            (["特来电", "特来电充电"], "特来电"),
            (["e充电", "E充电"], "e充电"),
            (["南方电网", "南网"], "南方电网"),
            (["比亚迪", "BYD"], "比亚迪充电站"),
            (["理想", "Li Auto", "LIXIANG"], "理想充电站"),
            (["问界", "AITO"], "问界充电站"),
            (["极氪", "ZEEKR"], "极氪充电站")
        ]
        
        // 充电站后缀关键词（用于识别通用充电站名称）
        let stationSuffixes = ["充电站", "超充站", "极充站", "换电站", "充电桩", "充电点", "服务站"]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            print("处理行: \(trimmedLine)")
            
            // 1. 优先提取充电站名称
            if location.isEmpty {
                // 1.1 先尝试品牌关键词匹配
                var foundBrand = false
                for station in stationKeywords {
                    if station.keywords.contains(where: { trimmedLine.contains($0) }) {
                        location = station.name
                        print("✅ 识别到充电站(品牌): \(location)")
                        foundBrand = true
                        break
                    }
                }
                
                // 1.2 如果没找到品牌，尝试匹配通用充电站名称格式
                if !foundBrand {
                    for suffix in stationSuffixes {
                        if trimmedLine.contains(suffix) {
                            // 提取完整的站点名称（移除特殊字符，保留中文、英文、数字）
                            let cleanedLine = trimmedLine
                                .replacingOccurrences(of: "：", with: "")
                                .replacingOccurrences(of: ":", with: "")
                                .trimmingCharacters(in: .whitespaces)
                            
                            // 如果这行文字长度合理（5-30个字符）且包含充电站后缀，就认为是站点名称
                            if cleanedLine.count >= 5 && cleanedLine.count <= 30 {
                                location = cleanedLine
                                print("✅ 识别到充电站(通用): \(location)")
                                break
                            }
                        }
                    }
                }
            }
            
            // 2. 提取充电电量（匹配 "XX.X kWh" 或 "XX.X度"）
            if electricityKwh.isEmpty {
                // 匹配充电量相关的关键词
                let kwhKeywords = ["充电电量", "充电量", "电量", "度数", "已充电量"]
                let containsKwhKeyword = kwhKeywords.contains(where: { trimmedLine.contains($0) })
                
                if containsKwhKeyword || trimmedLine.range(of: #"(kWh|度|kwh|KWH)"#, options: [.regularExpression, .caseInsensitive]) != nil {
                    if let kwhMatch = trimmedLine.range(of: #"(\d+\.?\d*)\s*(kWh|度|kwh|KWH)"#, options: [.regularExpression, .caseInsensitive]) {
                        let kwhString = String(trimmedLine[kwhMatch])
                        if let number = extractNumber(from: kwhString) {
                            // 智能格式化：保留有效小数位（如36.170度保留为36.17）
                            let formatter = NumberFormatter()
                            formatter.minimumFractionDigits = 1
                            formatter.maximumFractionDigits = 3
                            formatter.numberStyle = .decimal
                            
                            if let formatted = formatter.string(from: NSNumber(value: number)) {
                                electricityKwh = formatted
                            } else {
                                electricityKwh = String(format: "%.1f", number)
                            }
                            print("✅ 提取到充电电量: \(electricityKwh) kWh")
                        }
                    }
                }
            }
            
            // 3. 提取电费（匹配 "电费" 后面的数字）
            if electricityAmount.isEmpty {
                let keywords = ["电费", "充电费", "电量费", "电费金额", "电费：", "电费:"]
                for keyword in keywords {
                    if trimmedLine.contains(keyword) {
                        if let amount = extractNumber(from: trimmedLine) {
                            electricityAmount = String(format: "%.2f", amount)
                            print("✅ 提取到电费: ¥\(electricityAmount)")
                            break
                        }
                    }
                }
            }
            
            // 4. 提取服务费
            if serviceFee.isEmpty {
                let serviceKeywords = ["服务费", "服务费：", "服务费:"]
                for keyword in serviceKeywords {
                    if trimmedLine.contains(keyword) {
                        if let fee = extractNumber(from: trimmedLine) {
                            serviceFee = String(format: "%.2f", fee)
                            print("✅ 提取到服务费: ¥\(serviceFee)")
                            break
                        }
                    }
                }
            }
            
            // 5. 提取实付金额（总金额）
            if totalAmount.isEmpty {
                // 实付优先，然后是其他总额关键词
                let totalKeywords = ["实付", "实付金额", "实付：", "实付:", "总金额", "总计", "合计", "应付", "支付金额"]
                for keyword in totalKeywords {
                    if trimmedLine.contains(keyword) {
                        if let amount = extractNumber(from: trimmedLine) {
                            totalAmount = String(format: "%.2f", amount)
                            print("✅ 提取到实付金额: ¥\(totalAmount) (关键词: \(keyword))")
                            break
                        }
                    }
                }
            }
            
            // 6. 先提取极分抵扣（优先级高，避免与积分混淆）
            if pointsDiscount.isEmpty && (trimmedLine.contains("极分") || trimmedLine.contains("积分")) && trimmedLine.contains("-") {
                // 提取抵扣金额
                if let amount = extractNumber(from: trimmedLine) {
                    pointsDiscount = String(format: "%.2f", amount)
                    print("✅ 提取到极分抵扣金额: ¥\(pointsDiscount)")
                }
                
                // 同时提取括号内的积分数字 - 支持多种格式
                if points.isEmpty {
                    // 尝试多种括号格式：() 【】 （）
                    let patterns = [
                        #"\((\d+)(极分|积分)\)"#,      // (232极分)
                        #"（(\d+)(极分|积分)）"#,      // （232极分）
                        #"\[(\d+)(极分|积分)\]"#,      // [232极分]
                        #"【(\d+)(极分|积分)】"#        // 【232极分】
                    ]
                    
                    for pattern in patterns {
                        if let match = trimmedLine.range(of: pattern, options: .regularExpression) {
                            let matchedString = String(trimmedLine[match])
                            if let number = extractNumber(from: matchedString) {
                                points = String(format: "%.0f", number)
                                print("✅ 提取到积分(从抵扣行): \(points) 极分")
                                break
                            }
                        }
                    }
                }
            }
            
            // 7. 提取普通积分信息（不包含减号的）
            if points.isEmpty && !trimmedLine.contains("-") {
                // 匹配 "极分" 或 "积分" 相关的行
                let pointsKeywords = ["极分", "积分", "Points"]
                for keyword in pointsKeywords {
                    if trimmedLine.contains(keyword) {
                        print("  尝试从行中提取积分: \(trimmedLine)")
                        
                        // 尝试多种括号格式
                        let patterns = [
                            #"\((\d+)(极分|积分)\)"#,      // (232极分)
                            #"（(\d+)(极分|积分)）"#,      // （232极分）
                            #"\[(\d+)(极分|积分)\]"#,      // [232极分]
                            #"【(\d+)(极分|积分)】"#        // 【232极分】
                        ]
                        
                        var found = false
                        for pattern in patterns {
                            if let match = trimmedLine.range(of: pattern, options: .regularExpression) {
                                let matchedString = String(trimmedLine[match])
                                if let number = extractNumber(from: matchedString) {
                                    points = String(format: "%.0f", number)
                                    print("✅ 提取到积分: \(points) 极分")
                                    found = true
                                    break
                                }
                            }
                        }
                        
                        // 如果括号格式都不匹配，直接提取行中的数字
                        if !found, let amount = extractNumber(from: trimmedLine) {
                            points = String(format: "%.0f", amount)
                            print("✅ 提取到积分(数字): \(points)")
                        }
                        break
                    }
                }
            }
            
            // 8. 提取极能抵扣
            if energyDiscount.isEmpty && trimmedLine.contains("极能抵扣") {
                energyDiscount = trimmedLine
                    .replacingOccurrences(of: "极能抵扣", with: "")
                    .trimmingCharacters(in: .whitespaces)
                print("✅ 提取到极能抵扣: \(energyDiscount)")
            }
            
            // 9. 提取优惠券
            if couponDiscount.isEmpty && trimmedLine.contains("优惠券") && trimmedLine.contains("-") {
                if let amount = extractNumber(from: trimmedLine) {
                    couponDiscount = String(format: "%.2f", amount)
                    print("✅ 提取到优惠券: ¥\(couponDiscount)")
                }
            }
            
            // 10. 提取充电时间
            if chargingTime == nil {
                let timeKeywords = ["开始充电时间", "充电时间", "开始时间"]
                for keyword in timeKeywords {
                    if trimmedLine.contains(keyword) {
                        var parsedDate: Date?
                        
                        // 尝试匹配完整时间格式：2025-10-03 16:24:08 或 2025年10月3日 16:24:08
                        let fullPattern = #"(\d{4}[-年]\d{1,2}[-月]\d{1,2}[日\s]+\d{1,2}:\d{1,2}:\d{1,2})"#
                        if let match = trimmedLine.range(of: fullPattern, options: .regularExpression) {
                            let timeString = String(trimmedLine[match])
                                .replacingOccurrences(of: "年", with: "-")
                                .replacingOccurrences(of: "月", with: "-")
                                .replacingOccurrences(of: "日", with: "")
                                .trimmingCharacters(in: .whitespaces)
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            parsedDate = dateFormatter.date(from: timeString)
                        }
                        
                        // 如果上面没匹配到，尝试匹配无年份格式：10月01日 20:39:32
                        if parsedDate == nil {
                            let shortPattern = #"(\d{1,2})月(\d{1,2})日\s+(\d{1,2}):(\d{1,2}):(\d{1,2})"#
                            if let match = trimmedLine.range(of: shortPattern, options: .regularExpression) {
                                let matchedString = String(trimmedLine[match])
                                
                                // 获取当前年份
                                let calendar = Calendar.current
                                let currentYear = calendar.component(.year, from: Date())
                                
                                // 重新构建完整时间字符串
                                let fullTimeString = "\(currentYear)-" + matchedString
                                    .replacingOccurrences(of: "月", with: "-")
                                    .replacingOccurrences(of: "日", with: "")
                                    .trimmingCharacters(in: .whitespaces)
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                parsedDate = dateFormatter.date(from: fullTimeString)
                            }
                        }
                        
                        if let date = parsedDate {
                            chargingTime = date
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            print("✅ 提取到充电时间: \(formatter.string(from: date))")
                        }
                        break
                    }
                }
            }
        }
        
        // 11. 生成备注（当实付为0或有额外信息时）
        let totalAmountValue = Double(totalAmount) ?? 0
        
        if totalAmountValue == 0.0 || !energyDiscount.isEmpty || !pointsDiscount.isEmpty || !couponDiscount.isEmpty {
            // 添加极能抵扣信息
            if !energyDiscount.isEmpty {
                noteItems.append("极能抵扣: \(energyDiscount)")
            }
            
            // 添加极分抵扣信息
            if !pointsDiscount.isEmpty {
                if !points.isEmpty {
                    noteItems.append("极分抵扣: ¥\(pointsDiscount)(\(points)极分)")
                } else {
                    noteItems.append("极分抵扣: ¥\(pointsDiscount)")
                }
            }
            
            // 添加优惠券信息
            if !couponDiscount.isEmpty {
                noteItems.append("优惠券: -¥\(couponDiscount)")
            }
        }
        
        let notes = noteItems.joined(separator: ", ")
        
        // 格式化充电时间用于显示
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = chargingTime != nil ? timeFormatter.string(from: chargingTime!) : "未识别"
        
        print("📊 提取结果汇总:")
        print("  - 充电站: \(location.isEmpty ? "未识别" : location)")
        print("  - 充电电量: \(electricityKwh.isEmpty ? "未识别" : electricityKwh + " kWh")")
        print("  - 电费: \(electricityAmount.isEmpty ? "未识别" : "¥" + electricityAmount)")
        print("  - 服务费: \(serviceFee.isEmpty ? "未识别" : "¥" + serviceFee)")
        print("  - 实付: \(totalAmount.isEmpty ? "未识别" : "¥" + totalAmount)")
        print("  - 积分: \(points.isEmpty ? "未识别" : points + " 极分")")
        if !pointsDiscount.isEmpty {
            print("  - 极分抵扣: ¥\(pointsDiscount)")
        }
        if !energyDiscount.isEmpty {
            print("  - 极能抵扣: \(energyDiscount)")
        }
        if !couponDiscount.isEmpty {
            print("  - 优惠券: -¥\(couponDiscount)")
        }
        print("  - 充电时间: \(timeString)")
        print("  - 备注: \(notes.isEmpty ? "无" : notes)")
        
        // 保存提取的数据
        extractedData = ExtractedChargingData(
            electricityAmount: electricityAmount,
            serviceFee: serviceFee,
            electricityKwh: electricityKwh,
            location: location,
            totalAmount: totalAmount,
            points: points,
            notes: notes,
            chargingTime: chargingTime
        )
        
        // 如果识别到了站点，检查是否存在
        if !location.isEmpty {
            let stationExists = categories.contains { category in
                category.name == location || category.name.contains(location) || location.contains(category.name)
            }
            
            if !stationExists {
                // 站点不存在，显示确认弹窗
                recognizedStationName = location
                showingNewStationAlert = true
                print("站点 '\(location)' 不存在，询问用户是否创建")
            } else {
                // 站点存在，直接打开输入页面
                showingManualInput = true
            }
        } else {
            // 未识别到站点，直接打开输入页面
            showingManualInput = true
        }
    }
    
    // 从字符串中提取数字
    private func extractNumber(from text: String) -> Double? {
        // 替换中文符号和单位，保留空格以分隔数字
        let normalizedText = text
            .replacingOccurrences(of: "¥", with: " ")
            .replacingOccurrences(of: "￥", with: " ")
            .replacingOccurrences(of: "元", with: " ")
            .replacingOccurrences(of: "：", with: " ")
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "，", with: " ")
            .replacingOccurrences(of: "kWh", with: " ")
            .replacingOccurrences(of: "kwh", with: " ")
            .replacingOccurrences(of: "KWH", with: " ")
            .replacingOccurrences(of: "度", with: " ")
        
        // 匹配数字（支持小数点）
        let pattern = #"\d+\.?\d*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let matches = regex.matches(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText))
        
        // 提取所有数字
        var numbers: [Double] = []
        for match in matches {
            if let range = Range(match.range, in: normalizedText) {
                let numberString = String(normalizedText[range])
                if let number = Double(numberString) {
                    // 只保留合理范围内的数字（排除年份、日期等）
                    if number > 0 && number < 100000 {
                        numbers.append(number)
                        print("    发现数字: \(number)")
                    }
                }
            }
        }
        
        if numbers.isEmpty {
            return nil
        }
        
        // 如果只有一个数字，直接返回
        if numbers.count == 1 {
            return numbers[0]
        }
        
        // 如果有多个数字，优先返回带小数点的数字
        let decimalNumbers = numbers.filter { $0 != floor($0) }
        if !decimalNumbers.isEmpty {
            // 优先选择在合理金额范围内的小数（0.01-10000）
            let reasonableDecimals = decimalNumbers.filter { $0 >= 0.01 && $0 <= 10000 }
            if !reasonableDecimals.isEmpty {
                // 返回最大的合理小数
                return reasonableDecimals.max()
            }
            return decimalNumbers.max()
        }
        
        // 如果都是整数，返回最大的
        return numbers.max()
    }
}

// 提取的充电数据结构
struct ExtractedChargingData {
    let electricityAmount: String
    let serviceFee: String
    let electricityKwh: String
    let location: String
    let totalAmount: String
    let points: String
    let notes: String
    let chargingTime: Date?
}

// 可左滑的首页记录行组件
struct SwipeableHomeRecordRow: View {
    let record: ChargingRecord
    let currencySymbol: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
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
                ChargingRecordRow(record: record, currencySymbol: currencySymbol)
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

struct ChargingRecordRow: View {
    let record: ChargingRecord
    let currencySymbol: String
    @Environment(\.colorScheme) private var colorScheme
    
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
                
                Text("服务费\(currencySymbol)\(String(format: "%.0f", record.serviceFee))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(for: colorScheme))
                .shadow(color: Color.cardShadow(for: colorScheme), radius: 10, x: 0, y: 4)
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

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
