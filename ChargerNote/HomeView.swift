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
                        location: ""
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
        isProcessingImage = true
        
        guard let cgImage = image.cgImage else {
            isProcessingImage = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isProcessingImage = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.isProcessingImage = false
                }
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            print("识别的文本：\n\(recognizedText)")
            
            DispatchQueue.main.async {
                self.extractDataFromText(recognizedText)
                self.isProcessingImage = false
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
                    self.isProcessingImage = false
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
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            print("处理行: \(trimmedLine)")
            
            // 提取充电度数（匹配 "XX.X kWh" 或 "XX.X度"）
            if electricityKwh.isEmpty {
                if let kwhMatch = trimmedLine.range(of: #"(\d+\.?\d*)\s*(kWh|度|kwh|KWH)"#, options: [.regularExpression, .caseInsensitive]) {
                    let kwhString = String(trimmedLine[kwhMatch])
                    if let number = extractNumber(from: kwhString) {
                        electricityKwh = String(format: "%.1f", number)
                        print("提取到充电度数: \(electricityKwh)")
                    }
                }
            }
            
            // 提取电费金额（匹配 "电费"、"充电费"、"电量费" 后面的数字）
            if electricityAmount.isEmpty {
                let keywords = ["电费", "充电费", "电量费", "电费金额"]
                for keyword in keywords {
                    if trimmedLine.contains(keyword) {
                        if let amount = extractNumber(from: trimmedLine) {
                            electricityAmount = String(format: "%.2f", amount)
                            print("提取到电费: \(electricityAmount)")
                            break
                        }
                    }
                }
            }
            
            // 提取服务费
            if serviceFee.isEmpty {
                if trimmedLine.contains("服务费") {
                    if let fee = extractNumber(from: trimmedLine) {
                        serviceFee = String(format: "%.2f", fee)
                        print("提取到服务费: \(serviceFee)")
                    }
                }
            }
            
            // 提取总金额
            if totalAmount.isEmpty {
                let totalKeywords = ["总金额", "实付", "合计", "应付"]
                for keyword in totalKeywords {
                    if trimmedLine.contains(keyword) {
                        if let amount = extractNumber(from: trimmedLine) {
                            totalAmount = String(format: "%.2f", amount)
                            print("提取到总金额: \(totalAmount)")
                            break
                        }
                    }
                }
            }
            
            // 提取充电站点信息
            if location.isEmpty {
                if trimmedLine.contains("特斯拉") || trimmedLine.contains("Tesla") {
                    location = "特斯拉充电站"
                    print("识别到站点: \(location)")
                } else if trimmedLine.contains("小鹏") || trimmedLine.contains("XPENG") {
                    location = "小鹏充电站"
                    print("识别到站点: \(location)")
                } else if trimmedLine.contains("蔚来") || trimmedLine.contains("NIO") {
                    location = "蔚来换电站"
                    print("识别到站点: \(location)")
                } else if trimmedLine.contains("国家电网") || trimmedLine.contains("国网") {
                    location = "国家电网"
                    print("识别到站点: \(location)")
                }
            }
        }
        
        print("提取结果 - 度数:\(electricityKwh) 电费:\(electricityAmount) 服务费:\(serviceFee) 站点:\(location)")
        
        // 保存提取的数据
        extractedData = ExtractedChargingData(
            electricityAmount: electricityAmount,
            serviceFee: serviceFee,
            electricityKwh: electricityKwh,
            location: location
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
        // 替换中文符号为英文符号
        let normalizedText = text
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: "，", with: ",")
        
        // 匹配数字（支持小数）
        let pattern = #"(\d+\.?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let matches = regex.matches(in: normalizedText, range: NSRange(normalizedText.startIndex..., in: normalizedText))
        
        // 提取所有数字，返回最大的一个（通常金额是最大的数字）
        var numbers: [Double] = []
        for match in matches {
            if let range = Range(match.range, in: normalizedText) {
                if let number = Double(normalizedText[range]) {
                    numbers.append(number)
                }
            }
        }
        
        return numbers.max()
    }
}

// 提取的充电数据结构
struct ExtractedChargingData {
    let electricityAmount: String
    let serviceFee: String
    let electricityKwh: String
    let location: String
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
