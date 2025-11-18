//
//  NotificationManager.swift
//  AutoBookkeeping
//
//  通知管理器
//  负责所有应用通知和用户提醒
//

import Foundation
import UserNotifications

/// 通知管理器
/// 管理记账确认通知、预算预警等
@MainActor
class NotificationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationManager()

    private init() {
        setupNotificationCategories()
    }

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Authorization

    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            if granted {
                print("[NotificationManager] 通知权限已授予")
            } else {
                print("[NotificationManager] 通知权限被拒绝")
            }

            return granted
        } catch {
            print("[NotificationManager] 请求通知权限失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 检查通知权限状态
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Transaction Confirmation

    /// 发送交易确认通知
    /// - Parameter transaction: 交易对象
    func sendConfirmation(for transaction: Transaction) async {
        // 检查权限
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("[NotificationManager] 通知权限未授权，无法发送确认通知")
            return
        }

        // 构建通知内容
        let content = UNMutableNotificationContent()
        content.title = "✅ 自动记账成功"

        let typeEmoji = transaction.isExpense ? "💰" : "💵"
        let typeText = transaction.isExpense ? "支出" : "收入"

        content.body = """
        \(typeEmoji) \(transaction.merchant)
        ¥\(String(format: "%.2f", transaction.amount)) - \(transaction.categoryName)
        类型: \(typeText)
        """

        content.sound = .default
        content.categoryIdentifier = NotificationCategory.transactionConfirmation.rawValue

        // 附加用户信息（用于通知交互）
        content.userInfo = [
            "transactionId": transaction.id.uuidString,
            "type": NotificationCategory.transactionConfirmation.rawValue
        ]

        // 创建通知请求（立即发送）
        let request = UNNotificationRequest(
            identifier: "transaction_\(transaction.id.uuidString)",
            content: content,
            trigger: nil // 立即触发
        )

        // 发送通知
        do {
            try await notificationCenter.add(request)
            print("[NotificationManager] 交易确认通知已发送")
        } catch {
            print("[NotificationManager] 发送通知失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Budget Warning

    /// 发送预算预警通知
    /// - Parameters:
    ///   - category: 分类名称
    ///   - spent: 已花费金额
    ///   - budget: 预算金额
    ///   - percentage: 使用百分比
    func sendBudgetWarning(
        category: String,
        spent: Double,
        budget: Double,
        percentage: Double
    ) async {
        // 检查权限
        let status = await checkAuthorizationStatus()
        guard status == .authorized else { return }

        // 判断警告级别
        let warningLevel: BudgetWarningLevel
        if percentage >= 100 {
            warningLevel = .exceeded
        } else if percentage >= 90 {
            warningLevel = .critical
        } else {
            warningLevel = .warning
        }

        // 构建通知内容
        let content = UNMutableNotificationContent()
        content.title = warningLevel.title
        content.body = """
        \(category) 分类已使用 \(String(format: "%.0f", percentage))% 的预算

        已花费: ¥\(String(format: "%.2f", spent))
        预算: ¥\(String(format: "%.2f", budget))
        剩余: ¥\(String(format: "%.2f", max(0, budget - spent)))
        """

        content.sound = warningLevel == .exceeded ? .defaultCritical : .default
        content.categoryIdentifier = NotificationCategory.budgetWarning.rawValue

        content.userInfo = [
            "category": category,
            "spent": spent,
            "budget": budget,
            "percentage": percentage,
            "type": NotificationCategory.budgetWarning.rawValue
        ]

        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: "budget_\(category)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        // 发送通知
        do {
            try await notificationCenter.add(request)
            print("[NotificationManager] 预算预警通知已发送: \(category) - \(percentage)%")
        } catch {
            print("[NotificationManager] 发送预算预警失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Reminder

    /// 发送记账提醒
    /// - Parameter message: 提醒消息
    func sendReminder(message: String) async {
        let status = await checkAuthorizationStatus()
        guard status == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "📝 记账提醒"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("[NotificationManager] 发送提醒失败: \(error.localizedDescription)")
        }
    }

    /// 设置每日提醒
    /// - Parameters:
    ///   - hour: 小时 (0-23)
    ///   - minute: 分钟 (0-59)
    func scheduleDailyReminder(hour: Int, minute: Int) async {
        // 取消之前的每日提醒
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["daily_reminder"]
        )

        let content = UNMutableNotificationContent()
        content.title = "📊 今日记账提醒"
        content.body = "别忘了记录今天的支出哦~"
        content.sound = .default

        // 设置触发时间
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("[NotificationManager] 每日提醒已设置: \(hour):\(minute)")
        } catch {
            print("[NotificationManager] 设置每日提醒失败: \(error.localizedDescription)")
        }
    }

    /// 取消每日提醒
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["daily_reminder"]
        )
        print("[NotificationManager] 每日提醒已取消")
    }

    // MARK: - Notification Categories

    /// 设置通知分类和操作
    private func setupNotificationCategories() {
        // 交易确认通知的操作
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.viewTransaction.rawValue,
            title: "查看详情",
            options: .foreground
        )

        let editAction = UNNotificationAction(
            identifier: NotificationAction.editTransaction.rawValue,
            title: "修改分类",
            options: .foreground
        )

        let deleteAction = UNNotificationAction(
            identifier: NotificationAction.deleteTransaction.rawValue,
            title: "删除",
            options: .destructive
        )

        // 交易确认通知分类
        let transactionCategory = UNNotificationCategory(
            identifier: NotificationCategory.transactionConfirmation.rawValue,
            actions: [viewAction, editAction, deleteAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // 预算预警通知的操作
        let viewBudgetAction = UNNotificationAction(
            identifier: NotificationAction.viewBudget.rawValue,
            title: "查看预算",
            options: .foreground
        )

        let adjustBudgetAction = UNNotificationAction(
            identifier: NotificationAction.adjustBudget.rawValue,
            title: "调整预算",
            options: .foreground
        )

        // 预算预警通知分类
        let budgetCategory = UNNotificationCategory(
            identifier: NotificationCategory.budgetWarning.rawValue,
            actions: [viewBudgetAction, adjustBudgetAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // 注册通知分类
        notificationCenter.setNotificationCategories([
            transactionCategory,
            budgetCategory
        ])

        print("[NotificationManager] 通知分类已设置")
    }

    // MARK: - Notification Management

    /// 移除所有待发送的通知
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("[NotificationManager] 所有待发送通知已移除")
    }

    /// 移除所有已发送的通知
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        print("[NotificationManager] 所有已发送通知已移除")
    }

    /// 获取待发送通知数量
    func getPendingNotificationCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }

    /// 获取已发送通知数量
    func getDeliveredNotificationCount() async -> Int {
        let notifications = await notificationCenter.deliveredNotifications()
        return notifications.count
    }
}

// MARK: - Enums

/// 通知分类
enum NotificationCategory: String {
    case transactionConfirmation = "TRANSACTION_CONFIRMATION"
    case budgetWarning = "BUDGET_WARNING"
    case reminder = "REMINDER"
}

/// 通知操作
enum NotificationAction: String {
    case viewTransaction = "VIEW_TRANSACTION"
    case editTransaction = "EDIT_TRANSACTION"
    case deleteTransaction = "DELETE_TRANSACTION"
    case viewBudget = "VIEW_BUDGET"
    case adjustBudget = "ADJUST_BUDGET"
}

/// 预算警告级别
enum BudgetWarningLevel {
    case warning   // 80-89%
    case critical  // 90-99%
    case exceeded  // ≥100%

    var title: String {
        switch self {
        case .warning:
            return "⚠️ 预算提醒"
        case .critical:
            return "🚨 预算预警"
        case .exceeded:
            return "❌ 预算超支"
        }
    }
}

// MARK: - Notification Delegate

/// 通知代理（处理用户点击通知的操作）
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// 用户点击通知时调用
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            await handleNotificationAction(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo
            )
        }

        completionHandler()
    }

    /// 前台显示通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 在前台也显示通知
        completionHandler([.banner, .sound])
    }

    /// 处理通知操作
    private func handleNotificationAction(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let action = NotificationAction(rawValue: actionIdentifier) else {
            return
        }

        switch action {
        case .viewTransaction:
            if let transactionId = userInfo["transactionId"] as? String {
                NotificationCenter.default.post(
                    name: .openTransactionDetail,
                    object: transactionId
                )
            }

        case .editTransaction:
            if let transactionId = userInfo["transactionId"] as? String {
                NotificationCenter.default.post(
                    name: .openTransactionEditor,
                    object: transactionId
                )
            }

        case .deleteTransaction:
            if let transactionId = userInfo["transactionId"] as? String,
               let uuid = UUID(uuidString: transactionId) {
                // TODO: 删除交易
                print("[NotificationDelegate] 删除交易: \(uuid)")
            }

        case .viewBudget:
            if let category = userInfo["category"] as? String {
                NotificationCenter.default.post(
                    name: .openBudgetView,
                    object: category
                )
            }

        case .adjustBudget:
            if let category = userInfo["category"] as? String {
                NotificationCenter.default.post(
                    name: .openBudgetEditor,
                    object: category
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openTransactionDetail = Notification.Name("openTransactionDetail")
    static let openTransactionEditor = Notification.Name("openTransactionEditor")
    static let openBudgetView = Notification.Name("openBudgetView")
    static let openBudgetEditor = Notification.Name("openBudgetEditor")
}
