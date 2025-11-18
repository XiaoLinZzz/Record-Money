//
//  ColorPickerView.swift
//  AutoBookkeeping
//
//  颜色选择器
//

import SwiftUI

struct ColorPickerView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Binding var selectedColor: Color

    // MARK: - Colors

    private let colors: [Color] = [
        // 暖色系
        Color(red: 1.0, green: 0.42, blue: 0.42),     // 红色
        Color(red: 1.0, green: 0.63, blue: 0.48),     // 橙色
        Color(red: 0.97, green: 0.86, blue: 0.44),    // 黄色
        Color(red: 1.0, green: 0.44, blue: 0.57),     // 粉色

        // 冷色系
        Color(red: 0.31, green: 0.78, blue: 0.47),    // 绿色
        Color(red: 0.27, green: 0.71, blue: 0.71),    // 青色
        Color(red: 0.27, green: 0.55, blue: 0.88),    // 蓝色
        Color(red: 0.73, green: 0.56, blue: 0.81),    // 紫色

        // 中性色
        Color(red: 0.59, green: 0.59, blue: 0.59),    // 灰色
        Color(red: 0.64, green: 0.48, blue: 0.36),    // 棕色
        Color(red: 0.36, green: 0.64, blue: 0.58),    // 青绿色
        Color(red: 0.81, green: 0.56, blue: 0.81),    // 淡紫色
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 当前选择预览
                VStack(spacing: 12) {
                    Text("当前颜色")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(selectedColor)
                        .frame(width: 100, height: 100)
                        .shadow(color: selectedColor.opacity(0.4), radius: 10)
                }
                .padding()

                // 颜色网格
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 20) {
                    ForEach(colors, id: \.description) { color in
                        ColorButton(
                            color: color,
                            isSelected: colorsAreEqual(color, selectedColor)
                        ) {
                            selectedColor = color
                            HapticManager.shared.selectionChanged()
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                        HapticManager.shared.success()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func colorsAreEqual(_ color1: Color, _ color2: Color) -> Bool {
        // 简单比较（可以改进为更精确的比较）
        return color1.description == color2.description
    }
}

// MARK: - Color Button

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 4)
                )
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.3), radius: isSelected ? 8 : 4)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

// MARK: - Preview

#Preview {
    ColorPickerView(selectedColor: .constant(.blue))
}
