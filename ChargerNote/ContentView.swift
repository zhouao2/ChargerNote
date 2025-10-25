//
//  ContentView.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: TabBarView.Tab = .home

    var body: some View {
        TabBarView(selectedTab: $selectedTab)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, ChargingRecord.self], inMemory: true)
}
