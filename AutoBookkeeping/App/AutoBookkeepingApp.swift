//
//  AutoBookkeepingApp.swift
//  AutoBookkeeping
//
//  App 入口文件
//

import SwiftUI
import SwiftData

@main
struct AutoBookkeepingApp: App {

    // MARK: - Properties

    /// 数据管理器
    @StateObject private var dataManager = DataManager.shared

    /// 通知管理器
    @StateObject private var notificationManager = NotificationManager.shared

    /// 通知代理
    private let notificationDelegate = NotificationDelegate()

    // MARK: - Initialization

    init() {
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = notificationDelegate

        // 配置外观
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataManager.getModelContainer())
                .environmentObject(dataManager)
                .environmentObject(notificationManager)
                .task {
                    // 请求通知权限
                    _ = await notificationManager.requestAuthorization()
                }
        }
    }

    // MARK: - Configuration

    /// 配置应用外观
    private func configureAppearance() {
        // 配置导航栏外观
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance

        // 配置 TabBar 外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
