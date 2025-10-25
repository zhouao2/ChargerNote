//
//  HomeView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chargingRecords: [ChargingRecord]
    @State private var showingManualInput = false
    @State private var editingRecord: ChargingRecord?
    private let dataManager = DataManager.shared
    
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
                                    gradient: Gradient(colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.19, green: 0.69, blue: 0.31)]),
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
                                                
                                                Text("¥\(String(format: "%.2f", dataManager.getMonthlyExpense(for: Date(), records: chargingRecords)))")
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
                                            // TODO: 实现上传截图功能
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
                                                    .fill(Color.white)
                                                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
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
                                                    .fill(Color.white)
                                                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
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
                                                SwipeableHomeRecordRow(record: record, onEdit: {
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
        .sheet(isPresented: $showingManualInput) {
            ManualInputView()
        }
        .sheet(item: $editingRecord) { record in
            ManualInputView(editingRecord: record)
        }
    }
    
    private func deleteRecord(_ record: ChargingRecord) {
        modelContext.delete(record)
    }
}

// 可左滑的首页记录行组件
struct SwipeableHomeRecordRow: View {
    let record: ChargingRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    
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
                ChargingRecordRow(record: record)
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

struct ChargingRecordRow: View {
    let record: ChargingRecord
    
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
                Text("¥\(String(format: "%.2f", record.totalAmount))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("服务费¥\(String(format: "%.0f", record.serviceFee))")
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
    HomeView()
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
