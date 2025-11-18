//
//  ContentView.swift
//  AutoBookkeeping
//
//  主视图 - Tab Bar 导航
//

import SwiftUI

struct ContentView: View {

    // MARK: - State

    @State private var selectedTab = 0
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // 交易列表
            TransactionListView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            // 统计分析
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // 设置
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(DataManager.shared.getModelContainer())
}
