//
//  BudgetCardView.swift
//  AutoBookkeeping
//
//  预算卡片视图
//

import SwiftUI

struct BudgetCardView: View {

    // MARK: - Properties

    let budget: Budget
    @State private var detail: BudgetDetail?
    @State private var isLoading = true

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // 标题和金额
            HStack {
                Text(budget.categoryName)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let detail = detail {
                        Text("¥\(detail.spending, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(progressColor)
                        Text("/ ¥\(budget.amount, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }

            if let detail = detail {
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        // 进度
                        Rectangle()
                            .fill(progressColor)
                            .frame(width: min(geometry.size.width * detail.usage, geometry.size.width), height: 8)
                            .cornerRadius(4)
                            .animation(.spring(), value: detail.usage)
                    }
                }
                .frame(height: 8)

                // 百分比和剩余
                HStack {
                    Text("\(Int(detail.usage * 100))% 已使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if detail.isOver {
                        Text("超支 ¥\(detail.overage, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    } else {
                        Text("剩余 ¥\(detail.remaining, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: progressColor.opacity(0.2), radius: 5, x: 0, y: 2)
        .task {
            await loadDetail()
        }
    }

    // MARK: - Computed Properties

    private var progressColor: Color {
        guard let detail = detail else { return .blue }

        switch detail.usage {
        case 0..<0.7: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }

    // MARK: - Methods

    private func loadDetail() async {
        isLoading = true
        defer { isLoading = false }

        detail = await BudgetManager.shared.getBudgetDetail(budget: budget)
    }
}

// MARK: - Preview

#Preview {
    BudgetCardView(budget: Budget.preview)
        .padding()
}
