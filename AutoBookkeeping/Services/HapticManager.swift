//
//  HapticManager.swift
//  AutoBookkeeping
//
//  触觉反馈管理器
//  统一管理所有触觉反馈，提升用户体验
//

import UIKit

/// 触觉反馈管理器
/// 单例模式，提供统一的触觉反馈接口
@MainActor
class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Properties

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // 初始化时准备所有生成器，减少首次触发的延迟
        prepare()
    }

    // MARK: - Public Methods

    /// 操作成功反馈
    /// 使用场景：保存成功、更新成功、删除成功等
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// 操作失败反馈
    /// 使用场景：保存失败、网络错误、验证失败等
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// 警告反馈
    /// 使用场景：预算超支、数据冲突、需要用户注意等
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// 轻量级触碰反馈
    /// 使用场景：按钮点击、标签页切换、轻量级交互
    func lightImpact() {
        impactLight.impactOccurred()
    }

    /// 中等强度触碰反馈
    /// 使用场景：下拉刷新、滑动操作、中等交互
    func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// 重量级触碰反馈
    /// 使用场景：删除操作、重要确认、关键操作
    func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    /// 选择改变反馈
    /// 使用场景：分段控制切换、选择器滚动、筛选标签切换
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }

    /// 准备所有生成器
    /// 提前准备可以减少首次触发时的延迟
    func prepare() {
        notificationGenerator.prepare()
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Convenience Methods

    /// 触碰反馈（根据强度自动选择）
    /// - Parameter intensity: 强度（0.0-1.0）
    func impact(intensity: Double = 0.5) {
        switch intensity {
        case 0.0..<0.3:
            lightImpact()
        case 0.3..<0.7:
            mediumImpact()
        default:
            heavyImpact()
        }
    }

    /// 批量操作反馈
    /// 使用场景：批量删除、批量更新
    func batchOperation() {
        mediumImpact()
        // 短暂延迟后再次反馈，增强批量操作的感知
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            lightImpact()
        }
    }
}

// MARK: - Usage Examples (for reference)

/*
 使用示例：

 // 1. 保存成功
 HapticManager.shared.success()

 // 2. 删除操作
 HapticManager.shared.heavyImpact()

 // 3. 按钮点击
 HapticManager.shared.lightImpact()

 // 4. 切换标签
 HapticManager.shared.selectionChanged()

 // 5. 下拉刷新完成
 HapticManager.shared.mediumImpact()

 // 6. 表单验证失败
 HapticManager.shared.error()

 // 7. 预算超支警告
 HapticManager.shared.warning()
 */
