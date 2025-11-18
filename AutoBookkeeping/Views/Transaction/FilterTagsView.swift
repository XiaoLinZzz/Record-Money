//
//  FilterTagsView.swift
//  AutoBookkeeping
//
//  筛选标签视图
//  横向滚动的筛选标签
//

import SwiftUI

struct FilterTagsView: View {

    // MARK: - Properties

    @Binding var filter: TransactionFilter
    let categories: [String]
    let onAdvancedFilter: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 交易类型标签
                ForEach(TransactionFilter.TransactionType.allCases) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: filter.selectedType == type,
                        icon: type == .income ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                    ) {
                        toggleType(type)
                    }
                }

                Divider()
                    .frame(height: 30)

                // 分类标签
                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        title: category,
                        isSelected: filter.selectedCategories.contains(category),
                        icon: nil
                    ) {
                        toggleCategory(category)
                    }
                }

                Divider()
                    .frame(height: 30)

                // 高级筛选按钮
                Button {
                    onAdvancedFilter()
                    HapticManager.shared.lightImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("更多")
                        if filter.activeFilterCount > 0 {
                            Text("(\(filter.activeFilterCount))")
                                .font(.caption2)
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        filter.activeFilterCount > 0
                            ? Color.blue.opacity(0.1)
                            : Color.gray.opacity(0.1)
                    )
                    .foregroundColor(filter.activeFilterCount > 0 ? .blue : .secondary)
                    .cornerRadius(20)
                }

                // 清除筛选按钮
                if filter.isActive {
                    Button {
                        clearFilter()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("清除")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
    }

    // MARK: - Methods

    private func toggleCategory(_ category: String) {
        if filter.selectedCategories.contains(category) {
            filter.selectedCategories.remove(category)
        } else {
            filter.selectedCategories.insert(category)
        }
        HapticManager.shared.selectionChanged()
    }

    private func toggleType(_ type: TransactionFilter.TransactionType) {
        if filter.selectedType == type {
            filter.selectedType = nil
        } else {
            filter.selectedType = type
        }
        HapticManager.shared.selectionChanged()
    }

    private func clearFilter() {
        filter.clear()
        HapticManager.shared.mediumImpact()
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.blue
                    : Color.gray.opacity(0.1)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview

#Preview {
    FilterTagsView(
        filter: .constant(TransactionFilter()),
        categories: ["餐饮", "交通", "购物", "娱乐"],
        onAdvancedFilter: {}
    )
}
