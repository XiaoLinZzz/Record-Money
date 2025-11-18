//
//  AddCategoryView.swift
//  AutoBookkeeping
//
//  添加/编辑分类视图
//

import SwiftUI

struct AddCategoryView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - Properties

    let category: Category?  // nil = 新建，否则为编辑

    // MARK: - State

    @State private var name: String
    @State private var icon: String
    @State private var color: Color
    @State private var keywords: String

    @State private var showIconPicker = false
    @State private var showColorPicker = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(category: Category? = nil) {
        self.category = category

        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? "tag")
        _color = State(initialValue: category?.colorValue ?? .blue)
        _keywords = State(initialValue: category?.keywords.joined(separator: ", ") ?? "")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 预览
                Section {
                    HStack(spacing: 16) {
                        Spacer()

                        VStack(spacing: 12) {
                            // 图标预览
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(color)
                            }

                            Text(name.isEmpty ? "分类名称" : name)
                                .font(.headline)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 16)
                }

                // 基本信息
                Section("基本信息") {
                    TextField("分类名称", text: $name)
                        .onChange(of: name) { _, _ in
                            HapticManager.shared.lightImpact()
                        }

                    // 图标选择
                    Button {
                        showIconPicker = true
                        HapticManager.shared.lightImpact()
                    } label: {
                        HStack {
                            Text("图标")
                            Spacer()
                            Image(systemName: icon)
                                .foregroundColor(color)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 颜色选择
                    Button {
                        showColorPicker = true
                        HapticManager.shared.lightImpact()
                    } label: {
                        HStack {
                            Text("颜色")
                            Spacer()
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 关键词
                Section {
                    TextField("例如：麦当劳, 肯德基, 餐厅", text: $keywords)
                        .onChange(of: keywords) { _, _ in
                            HapticManager.shared.lightImpact()
                        }
                } header: {
                    Text("关键词")
                } footer: {
                    Text("用逗号分隔多个关键词，用于智能分类识别")
                }
            }
            .navigationTitle(category == nil ? "新建分类" : "编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(category == nil ? "创建" : "保存") {
                        Task {
                            await saveCategory()
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerView(selectedColor: $color)
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods

    private func saveCategory() async {
        guard isValid else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // 解析关键词
        let keywordArray = keywords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            if let existingCategory = category {
                // 编辑现有分类
                existingCategory.name = trimmedName
                existingCategory.icon = icon
                existingCategory.color = colorToHex(color)
                existingCategory.keywords = keywordArray
                existingCategory.updatedAt = Date()

                try await dataManager.saveContext()
            } else {
                // 创建新分类
                let newCategory = Category(
                    name: trimmedName,
                    icon: icon,
                    color: colorToHex(color),
                    isCustom: true
                )
                newCategory.keywords = keywordArray

                try await dataManager.saveCategory(newCategory)
            }

            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    private func colorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        guard let components = uiColor.cgColor.components else { return "#000000" }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Preview

#Preview {
    AddCategoryView()
        .environmentObject(DataManager.shared)
}
