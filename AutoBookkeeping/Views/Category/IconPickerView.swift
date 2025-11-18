//
//  IconPickerView.swift
//  AutoBookkeeping
//
//  图标选择器
//  从 SF Symbols 中选择图标
//

import SwiftUI

struct IconPickerView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Binding var selectedIcon: String

    // MARK: - Icons Database

    private let iconGroups: [String: [String]] = [
        "餐饮": ["fork.knife", "cup.and.saucer", "birthday.cake", "wineglass", "mug", "takeoutbag.and.cup.and.straw"],
        "交通": ["car", "bus", "tram", "airplane", "bicycle", "scooter", "ferry", "cablecar"],
        "购物": ["cart", "bag", "gift", "creditcard", "basket", "handbag"],
        "娱乐": ["gamecontroller", "tv", "music.note", "film", "theatermasks", "guitars"],
        "医疗": ["cross.case", "pills", "heart", "bandage", "heart.text.square", "medical.thermometer"],
        "教育": ["book", "graduationcap", "pencil", "paperplane", "character.book.closed", "backpack"],
        "生活": ["house", "lightbulb", "wifi", "phone", "key", "lamp.desk"],
        "其他": ["ellipsis.circle", "star", "flag", "tag", "bookmark", "sparkles"]
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                ForEach(iconGroups.keys.sorted(), id: \.self) { group in
                    Section(group) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                            ForEach(iconGroups[group]!, id: \.self) { icon in
                                IconButton(
                                    icon: icon,
                                    isSelected: selectedIcon == icon
                                ) {
                                    selectedIcon = icon
                                    HapticManager.shared.selectionChanged()
                                    dismiss()
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }
            }
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 60, height: 60)
                .background(
                    isSelected
                        ? Color.blue
                        : Color.gray.opacity(0.15)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    IconPickerView(selectedIcon: .constant("fork.knife"))
}
