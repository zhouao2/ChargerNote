//
//  TabBarView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData

struct TabBarView: View {
    @Binding var selectedTab: Tab
    @State private var showingManualInput = false
    
    enum Tab: Int, CaseIterable {
        case home = 0
        case analytics = 1
        case history = 2
        case settings = 3
        
        var title: String {
            switch self {
            case .home: return "记账"
            case .analytics: return "统计"
            case .history: return "历史"
            case .settings: return "设置"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .analytics: return "chart.bar"
            case .history: return "clock"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要内容区域 - 根据选中的tab显示对应视图
            ZStack {
                if selectedTab == .home {
                    HomeView()
                } else if selectedTab == .analytics {
                    AnalyticsView()
                } else if selectedTab == .history {
                    HistoryView()
                } else if selectedTab == .settings {
                    SettingsView()
                }
            }
            
            // 底部导航栏
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .green : .gray)
                            
                            Text(tab.title)
                                .font(.system(size: 12, weight: selectedTab == tab ? .medium : .regular))
                                .foregroundColor(selectedTab == tab ? .green : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: -1)
            )
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .sheet(isPresented: $showingManualInput) {
            ManualInputView()
        }
    }
}

#Preview {
    TabBarView(selectedTab: .constant(.home))
        .modelContainer(for: ChargingRecord.self, inMemory: true)
}
