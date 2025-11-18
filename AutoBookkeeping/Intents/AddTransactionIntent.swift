//
//  AddTransactionIntent.swift
//  AutoBookkeeping
//
//  添加交易记录的 App Intent
//  这是快捷指令调用的核心接口
//

import AppIntents
import Foundation

/// 添加交易记录的 Intent
/// 用于快捷指令自动化调用，支持后台执行
struct AddTransactionIntent: AppIntent {

    // MARK: - Intent Configuration

    static var title: LocalizedStringResource = "添加交易记录"

    static var description = IntentDescription(
        "自动记录一笔交易，支持智能分类",
        categoryName: "记账",
        searchKeywords: ["记账", "交易", "支出", "收入"]
    )

    // 后台执行，不打开 App
    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    /// 交易金额（必需）
    @Parameter(
        title: "金额",
        description: "交易金额（元）",
        inputOptions: String.IntentInputOptions(
            keyboardType: .decimalPad
        )
    )
    var amount: Double

    /// 商家名称（可选）
    @Parameter(
        title: "商家名称",
        description: "支付给谁或从哪里收到"
    )
    var merchant: String?

    /// 交易类型（必需）
    @Parameter(
        title: "交易类型",
        description: "支出或收入",
        default: .expense
    )
    var type: TransactionType

    /// OCR 识别的原始文本（可选）
    @Parameter(
        title: "原始文本",
        description: "从支付页面识别的完整文本"
    )
    var rawText: String?

    /// 支付方式（可选）
    @Parameter(
        title: "支付方式",
        description: "微信支付、支付宝等"
    )
    var paymentMethod: String?

    // MARK: - Initialization

    init() {}

    init(
        amount: Double,
        merchant: String? = nil,
        type: TransactionType = .expense,
        rawText: String? = nil,
        paymentMethod: String? = nil
    ) {
        self.amount = amount
        self.merchant = merchant
        self.type = type
        self.rawText = rawText
        self.paymentMethod = paymentMethod
    }

    // MARK: - Perform

    /// 执行记账逻辑
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 参数验证
        guard amount > 0 else {
            throw IntentError.invalidAmount
        }

        // 确保商家名称不为空
        let merchantName = merchant?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "未知商家"

        do {
            // 1. 智能分类推断
            let categoryName = await CategoryEngine.shared.inferCategory(
                merchant: merchantName,
                rawText: rawText
            )

            // 2. 创建交易记录
            let transaction = Transaction(
                amount: amount,
                merchant: merchantName,
                categoryName: categoryName,
                type: type.rawValue,
                paymentMethod: paymentMethod,
                rawText: rawText,
                timestamp: Date()
            )

            // 3. 保存到数据库
            try await DataManager.shared.saveTransaction(transaction)

            // 4. 发送确认通知
            await NotificationManager.shared.sendConfirmation(for: transaction)

            // 5. 检查预算警告（如果启用了预算）
            await checkBudgetWarning(
                categoryName: categoryName,
                amount: amount,
                type: type
            )

            // 6. 返回成功结果
            let message = buildSuccessMessage(
                merchant: merchantName,
                amount: amount,
                category: categoryName,
                type: type
            )

            return .result(dialog: message)

        } catch {
            // 记录错误日志
            logError(error)

            // 返回错误信息
            throw IntentError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    /// 构建成功消息
    private func buildSuccessMessage(
        merchant: String,
        amount: Double,
        category: String,
        type: TransactionType
    ) -> String {
        let typeEmoji = type == .expense ? "💰" : "💵"
        let typeText = type == .expense ? "支出" : "收入"

        return """
        \(typeEmoji) 记账成功

        商家: \(merchant)
        金额: ¥\(String(format: "%.2f", amount))
        分类: \(category)
        类型: \(typeText)
        """
    }

    /// 检查预算警告
    private func checkBudgetWarning(
        categoryName: String,
        amount: Double,
        type: TransactionType
    ) async {
        // 只对支出检查预算
        guard type == .expense else { return }

        // 获取当月该分类的总支出
        if let budget = await DataManager.shared.getBudget(for: categoryName),
           budget.isEnabled {

            let monthlySpent = await DataManager.shared.getMonthlySpent(
                for: categoryName
            )

            let percentage = (monthlySpent / budget.amount) * 100

            // 超过 80% 发送警告
            if percentage >= 80 {
                await NotificationManager.shared.sendBudgetWarning(
                    category: categoryName,
                    spent: monthlySpent,
                    budget: budget.amount,
                    percentage: percentage
                )
            }
        }
    }

    /// 记录错误日志
    private func logError(_ error: Error) {
        print("[AddTransactionIntent] Error: \(error.localizedDescription)")
        // TODO: 集成日志系统（如 OSLog）
    }
}

// MARK: - Transaction Type Enum

/// 交易类型枚举
enum TransactionType: String, AppEnum {
    case expense = "expense"
    case income = "income"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "交易类型"
    )

    static var caseDisplayRepresentations: [TransactionType: DisplayRepresentation] = [
        .expense: DisplayRepresentation(
            title: "支出",
            subtitle: "花费的钱",
            image: .init(systemName: "arrow.down.circle.fill")
        ),
        .income: DisplayRepresentation(
            title: "收入",
            subtitle: "收到的钱",
            image: .init(systemName: "arrow.up.circle.fill")
        )
    ]
}

// MARK: - Intent Errors

/// Intent 错误类型
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case invalidMerchant
    case saveFailed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            return "金额必须大于 0"
        case .invalidMerchant:
            return "商家名称无效"
        case .saveFailed(let reason):
            return "保存失败: \(reason)"
        }
    }
}

// MARK: - App Shortcuts

/// 注册应用快捷指令
struct AutoBookkeepingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "用\(.applicationName)记账",
                "自动记账",
                "记一笔账到\(.applicationName)"
            ],
            shortTitle: "自动记账",
            systemImageName: "dollarsign.circle.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor = .orange
}
