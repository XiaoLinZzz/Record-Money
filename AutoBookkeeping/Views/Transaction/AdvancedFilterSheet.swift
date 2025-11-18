//
//  AdvancedFilterSheet.swift
//  AutoBookkeeping
//
//  高级筛选视图
//  支持日期范围、金额范围、支付方式等高级筛选
//

import SwiftUI

struct AdvancedFilterSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Binding var filter: TransactionFilter

    // MARK: - State

    @State private var selectedDatePreset: DatePreset?
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()

    @State private var minAmount: Double = 0
    @State private var maxAmount: Double = 10000

    @State private var showCustomDatePicker = false

    enum DatePreset: String, CaseIterable, Identifiable {
        case today = "今天"
        case thisWeek = "本周"
        case thisMonth = "本月"
        case last7Days = "最近7天"
        case last30Days = "最近30天"
        case custom = "自定义"

        var id: String { self.rawValue }

        func dateRange() -> TransactionFilter.DateRange? {
            switch self {
            case .today: return .today()
            case .thisWeek: return .thisWeek()
            case .thisMonth: return .thisMonth()
            case .last7Days: return .last7Days()
            case .last30Days: return .last30Days()
            case .custom: return nil
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 日期范围
                Section {
                    ForEach(DatePreset.allCases) { preset in
                        Button {
                            selectDatePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedDatePreset == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    if showCustomDatePicker {
                        DatePicker("开始日期", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                    }
                } header: {
                    Text("日期范围")
                } footer: {
                    if let range = filter.dateRange {
                        Text("已选择: \(formatDate(range.start)) - \(formatDate(range.end))")
                    }
                }

                // 金额范围
                Section {
                    HStack {
                        Text("最小金额")
                        Spacer()
                        TextField("0", value: $minAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("元")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("最大金额")
                        Spacer()
                        TextField("10000", value: $maxAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("元")
                            .foregroundColor(.secondary)
                    }

                    // 金额范围滑块
                    VStack(alignment: .leading, spacing: 8) {
                        Text("范围: ¥\(minAmount, specifier: "%.0f") - ¥\(maxAmount, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // 双向滑块（简化版本，使用两个独立滑块）
                        VStack(spacing: 4) {
                            Slider(value: $minAmount, in: 0...maxAmount, step: 10) {
                                Text("最小")
                            }
                            .onChange(of: minAmount) { _, _ in
                                HapticManager.shared.selectionChanged()
                            }

                            Slider(value: $maxAmount, in: minAmount...20000, step: 10) {
                                Text("最大")
                            }
                            .onChange(of: maxAmount) { _, _ in
                                HapticManager.shared.selectionChanged()
                            }
                        }
                    }
                } header: {
                    Text("金额范围")
                }

                // 支付方式
                Section("支付方式") {
                    ForEach(getAvailablePaymentMethods(), id: \.self) { method in
                        Button {
                            togglePaymentMethod(method)
                        } label: {
                            HStack {
                                Text(method)
                                    .foregroundColor(.primary)
                                Spacer()
                                if filter.selectedPaymentMethods.contains(method) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // 操作按钮
                Section {
                    Button(role: .destructive) {
                        clearAllFilters()
                    } label: {
                        Label("清除所有筛选", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("高级筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        applyFilters()
                    }
                }
            }
        }
    }

    // MARK: - Methods

    private func selectDatePreset(_ preset: DatePreset) {
        selectedDatePreset = preset
        showCustomDatePicker = (preset == .custom)

        if preset != .custom {
            filter.dateRange = preset.dateRange()
        }

        HapticManager.shared.selectionChanged()
    }

    private func togglePaymentMethod(_ method: String) {
        if filter.selectedPaymentMethods.contains(method) {
            filter.selectedPaymentMethods.remove(method)
        } else {
            filter.selectedPaymentMethods.insert(method)
        }
        HapticManager.shared.selectionChanged()
    }

    private func applyFilters() {
        // 应用金额范围
        if minAmount > 0 || maxAmount < 10000 {
            filter.amountRange = TransactionFilter.AmountRange(
                min: minAmount,
                max: maxAmount
            )
        } else {
            filter.amountRange = nil
        }

        // 应用自定义日期范围
        if showCustomDatePicker {
            filter.dateRange = TransactionFilter.DateRange(
                start: customStartDate,
                end: customEndDate
            )
        }

        HapticManager.shared.success()
        dismiss()
    }

    private func clearAllFilters() {
        filter.clear()
        selectedDatePreset = nil
        showCustomDatePicker = false
        minAmount = 0
        maxAmount = 10000

        HapticManager.shared.mediumImpact()
    }

    private func getAvailablePaymentMethods() -> [String] {
        return ["手动添加", "OCR识别", "智能输入", "快捷指令"]
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    AdvancedFilterSheet(filter: .constant(TransactionFilter()))
}
