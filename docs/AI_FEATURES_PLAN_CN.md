# AI 功能实施计划（中国本地化版）

> 创建时间: 2024-11-18
> **核心原则**: 完全本地运行 + 零额外费用 + 隐私安全

---

## 🎯 设计原则

### 关键约束

✅ **必须满足**：
1. **完全离线可用** - 所有 AI 功能在设备本地运行
2. **零额外费用** - 不使用任何付费云端 API
3. **中国可用** - 不依赖被墙的服务（OpenAI、Google 等）
4. **隐私安全** - 用户数据不上传到任何服务器
5. **Apple 原生** - 优先使用 Apple 官方框架

❌ **绝对不用**：
1. OpenAI ChatGPT API（付费 + 中国不可用）
2. Google Cloud AI（付费 + 中国不可用）
3. Azure Cognitive Services（付费）
4. 任何云端推理服务

### 技术选型

| 功能 | 技术方案 | 是否收费 | 是否可用 | 是否离线 |
|------|---------|---------|---------|---------|
| **智能分类** | CoreML + Create ML | ❌ 免费 | ✅ 可用 | ✅ 离线 |
| **小票扫描** | Vision Framework | ❌ 免费 | ✅ 可用 | ✅ 离线 |
| **对话记账** | NaturalLanguage + 规则引擎 | ❌ 免费 | ✅ 可用 | ✅ 离线 |
| **文本理解** | NLTagger + NSLinguisticTagger | ❌ 免费 | ✅ 可用 | ✅ 离线 |

---

## 📊 功能优先级重排（基于实用性和成本）

### Phase 1: OCR 小票扫描（最高优先级）⭐⭐⭐⭐⭐

**为什么优先做这个**：
- ✅ 技术成熟（Vision 框架）
- ✅ 用户价值高（手动输入太慢）
- ✅ 无需训练数据（开箱即用）
- ✅ 实施快速（预计 6-8 小时）

**用户场景**：
- 餐厅吃饭后拍小票 → 自动提取金额、商家、时间 → 一键保存
- 超市购物后拍收据 → 识别商品列表 → 批量记账

**技术实现**：
```
拍照/选择图片
    ↓
Vision VNRecognizeTextRequest（中文识别）
    ↓
正则表达式提取结构化数据
    ↓
预填充到记账表单
    ↓
用户确认并保存
```

**预计工时**: 6-8 小时

---

### Phase 2: CoreML 智能分类（高优先级）⭐⭐⭐⭐

**为什么第二优先**：
- ✅ 提升分类准确度（当前规则引擎已达 80%）
- ✅ 越用越准（持续学习）
- ⚠️ 需要训练数据（用户修正历史）
- ⚠️ 需要模型训练（Create ML）

**用户场景**：
- 新商家"喜茶"→ 规则引擎不认识 → ML 模型根据历史数据推断为"餐饮"
- 复杂商家"北京华联超市（朝阳店）"→ 传统规则难匹配 → ML 识别为"购物"

**技术路线**：
```
数据收集（用户修正历史）
    ↓
Create ML 训练文本分类模型
    ↓
导出 .mlmodel 文件
    ↓
集成到 App（CoreML）
    ↓
混合策略：规则引擎 + ML 模型
```

**数据来源**：
- 用户每次修改分类 → 记录（商家名, 修正后的分类）
- 累积 100+ 条数据后开始训练
- 定期更新模型（App 更新时）

**预计工时**: 12-16 小时

---

### Phase 3: 本地 NLP 对话记账（中优先级）⭐⭐⭐

**为什么第三优先**：
- ✅ 用户体验好（自然语言输入）
- ⚠️ 技术复杂（NLP 解析）
- ⚠️ 本地 NLP 能力有限（相比云端 GPT）

**用户场景**：
- 用户输入："今天中午星巴克花了35块"
  → 自动解析：时间=今天中午、商家=星巴克、金额=35、类型=支出
- 用户输入："昨天打车12.5元"
  → 自动解析：时间=昨天、分类=交通、金额=12.5

**技术方案**：
使用 **Apple NaturalLanguage 框架**（完全本地，无需网络）

```swift
import NaturalLanguage

// 1. 词性标注（找出金额、商家、时间）
let tagger = NLTagger(tagSchemes: [.tokenType, .lexicalClass, .nameType])
tagger.string = "今天中午星巴克花了35块"

// 2. 命名实体识别
tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                     unit: .word,
                     scheme: .nameType) { tag, range in
    if tag == .organizationName {
        merchant = String(text[range])  // "星巴克"
    }
}

// 3. 正则表达式提取金额
let amountRegex = /(\d+\.?\d*)([元块钱])?/
amount = amountRegex.firstMatch(in: text)  // 35

// 4. 时间识别
let timeRegex = /(今天|昨天|前天)(早上|中午|下午|晚上)?/
time = parseTime(timeRegex.firstMatch(in: text))  // 今天中午
```

**限制和降级方案**：
- ❌ 复杂语句可能识别不准（"给老王转了200，买咖啡用的"）
- ✅ 降级方案：识别不准时，显示原始文本 + 建议字段，让用户手动修正
- ✅ 简单语句准确率高（"星巴克35元"、"打车12.5"）

**预计工时**: 10-12 小时

---

## 🚀 详细实施方案

### Phase 1: OCR 小票扫描（6-8 小时）

#### 1.1 技术架构

```
┌─────────────────────────────────────┐
│  ReceiptScannerView                 │
│  ┌───────────────────────────────┐ │
│  │  相机预览 / 相册选择          │ │
│  └───────────────────────────────┘ │
│           ↓                         │
│  ┌───────────────────────────────┐ │
│  │  Vision OCR 识别              │ │
│  │  VNRecognizeTextRequest       │ │
│  └───────────────────────────────┘ │
│           ↓                         │
│  ┌───────────────────────────────┐ │
│  │  ReceiptParser                │ │
│  │  正则提取：金额/商家/时间     │ │
│  └───────────────────────────────┘ │
│           ↓                         │
│  ┌───────────────────────────────┐ │
│  │  预填充表单                   │ │
│  │  用户确认并保存               │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### 1.2 核心代码实现

**OCRManager.swift**

```swift
import Vision
import UIKit

@MainActor
class OCRManager {
    static let shared = OCRManager()

    /// 识别图片中的文本（支持中文）
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // 配置识别选项
            request.recognitionLevel = .accurate  // 准确度优先
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]  // 支持简体中文、繁体中文、英文
            request.usesLanguageCorrection = true  // 启用语言纠错

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum OCRError: Error {
    case invalidImage
    case noTextFound
    case parsingFailed
}
```

**ReceiptParser.swift**

```swift
import Foundation

struct ReceiptData {
    var amount: Double?
    var merchant: String?
    var date: Date?
    var items: [String]?
    var rawText: String
}

class ReceiptParser {

    /// 解析小票文本
    static func parse(_ text: String) -> ReceiptData {
        var data = ReceiptData(rawText: text)

        // 1. 提取金额（支持多种格式）
        data.amount = extractAmount(from: text)

        // 2. 提取商家名称
        data.merchant = extractMerchant(from: text)

        // 3. 提取日期时间
        data.date = extractDate(from: text)

        // 4. 提取商品列表（可选）
        data.items = extractItems(from: text)

        return data
    }

    // MARK: - 金额提取

    private static func extractAmount(from text: String) -> Double? {
        // 多种金额格式
        let patterns = [
            #"(?:合计|总计|应收|实收|小计)[:：\s]*¥?(\d+\.?\d*)"#,  // 合计：¥35.00
            #"(?:金额|总额)[:：\s]*(\d+\.?\d*)"#,                    // 金额：35.00
            #"¥\s*(\d+\.?\d*)"#,                                     // ¥35.00
            #"(\d+\.\d{2})\s*元"#                                    // 35.00元
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let amountRange = Range(match.range(at: 1), in: text) {
                let amountString = String(text[amountRange])
                if let amount = Double(amountString) {
                    return amount
                }
            }
        }

        return nil
    }

    // MARK: - 商家名称提取

    private static func extractMerchant(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)

        // 通常商家名称在前几行
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // 跳过发票抬头等无关信息
            if trimmed.isEmpty ||
               trimmed.contains("发票") ||
               trimmed.contains("收据") ||
               trimmed.count < 2 {
                continue
            }

            // 商家名称通常较长且不包含数字
            if trimmed.count >= 2 && trimmed.count <= 30 {
                // 优先返回不含数字的行
                if !trimmed.contains(where: { $0.isNumber }) {
                    return trimmed
                }
            }
        }

        return lines.first { !$0.isEmpty }
    }

    // MARK: - 日期提取

    private static func extractDate(from text: String) -> Date? {
        // 日期格式：2024-11-18、2024/11/18、20241118
        let patterns = [
            #"(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})"#,
            #"(\d{4})(\d{2})(\d{2})"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges >= 4 {

                let year = Int((text as NSString).substring(with: match.range(at: 1))) ?? 0
                let month = Int((text as NSString).substring(with: match.range(at: 2))) ?? 0
                let day = Int((text as NSString).substring(with: match.range(at: 3))) ?? 0

                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day

                if let date = Calendar.current.date(from: components) {
                    return date
                }
            }
        }

        return nil
    }

    // MARK: - 商品列表提取（可选）

    private static func extractItems(from text: String) -> [String]? {
        // 识别商品列表（通常包含价格）
        let lines = text.components(separatedBy: .newlines)
        var items: [String] = []

        for line in lines {
            // 商品行通常包含：商品名 + 价格
            if line.contains(where: { $0.isNumber }) &&
               line.count > 3 &&
               line.count < 50 {
                items.append(line.trimmingCharacters(in: .whitespaces))
            }
        }

        return items.isEmpty ? nil : items
    }
}
```

**ReceiptScannerView.swift**

```swift
import SwiftUI
import PhotosUI

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var selectedImage: UIImage?
    @State private var recognizedText = ""
    @State private var parsedData: ReceiptData?
    @State private var isProcessing = false
    @State private var showImagePicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 选择图片区域
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("点击选择小票图片")
                            .font(.headline)

                        Text("支持餐饮小票、购物收据等")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onTapGesture {
                        showImagePicker = true
                        HapticManager.shared.lightImpact()
                    }
                }

                // 识别结果
                if let data = parsedData {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("识别结果")
                            .font(.headline)

                        if let amount = data.amount {
                            Label("金额：¥\(String(format: "%.2f", amount))", systemImage: "yensign.circle.fill")
                                .foregroundColor(.green)
                        }

                        if let merchant = data.merchant {
                            Label("商家：\(merchant)", systemImage: "building.2.fill")
                                .foregroundColor(.blue)
                        }

                        if let date = data.date {
                            Label("日期：\(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }

                Spacer()

                // 操作按钮
                if selectedImage != nil {
                    HStack(spacing: 12) {
                        Button("重新选择") {
                            selectedImage = nil
                            parsedData = nil
                            recognizedText = ""
                            HapticManager.shared.lightImpact()
                        }
                        .buttonStyle(.bordered)

                        Button("识别并添加") {
                            Task {
                                await processImage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                    }
                } else {
                    Button("选择图片") {
                        showImagePicker = true
                        HapticManager.shared.lightImpact()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("扫描小票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .overlay {
                if isProcessing {
                    ProgressView("识别中...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Methods

    private func processImage() async {
        guard let image = selectedImage else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // 1. OCR 识别
            let text = try await OCRManager.shared.recognizeText(from: image)
            recognizedText = text

            // 2. 解析数据
            parsedData = ReceiptParser.parse(text)

            // 3. 如果识别成功，直接跳转到添加页面
            if let data = parsedData, data.amount != nil {
                HapticManager.shared.success()
                // 预填充数据到添加交易页面
                // TODO: 创建带预填充的 AddTransactionView
            } else {
                HapticManager.shared.warning()
                errorMessage = "未能识别完整信息，请手动补充"
            }

        } catch {
            HapticManager.shared.error()
            errorMessage = "识别失败: \(error.localizedDescription)"
        }
    }
}

// 简单的图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                HapticManager.shared.mediumImpact()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

#### 1.3 集成到 TransactionListView

```swift
// TransactionListView.swift

@State private var showReceiptScanner = false

.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        // OCR 扫描按钮
        Button {
            showReceiptScanner = true
            HapticManager.shared.lightImpact()
        } label: {
            Image(systemName: "doc.text.viewfinder")
        }

        // 手动添加按钮
        Button {
            showAddTransaction = true
            HapticManager.shared.lightImpact()
        } label: {
            Image(systemName: "plus.circle.fill")
        }
    }
}
.sheet(isPresented: $showReceiptScanner) {
    ReceiptScannerView()
}
```

**预计工时**: 6-8 小时

---

### Phase 2: CoreML 智能分类（12-16 小时）

#### 2.1 数据收集和准备

**MLTrainingDataManager.swift**

```swift
import Foundation

struct TrainingData: Codable {
    let merchant: String      // 商家名称
    let category: String      // 分类
    let timestamp: Date       // 时间戳
    let source: String        // 来源：user_correction / system_default
}

class MLTrainingDataManager {
    static let shared = MLTrainingDataManager()

    private let fileURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("training_data.json")
    }()

    private var trainingData: [TrainingData] = []

    init() {
        loadData()
    }

    /// 记录用户修正
    func recordCorrection(merchant: String, category: String) {
        let data = TrainingData(
            merchant: merchant,
            category: category,
            timestamp: Date(),
            source: "user_correction"
        )

        trainingData.append(data)
        saveData()
    }

    /// 导出 CSV 用于训练
    func exportCSV() -> String {
        var csv = "merchant,category\n"

        for data in trainingData {
            // 清理数据，移除逗号和换行符
            let cleanMerchant = data.merchant.replacingOccurrences(of: ",", with: " ")
            csv += "\"\(cleanMerchant)\",\(data.category)\n"
        }

        return csv
    }

    /// 获取数据量
    var dataCount: Int {
        trainingData.count
    }

    /// 是否有足够数据训练
    var hasEnoughData: Bool {
        dataCount >= 100  // 至少 100 条数据
    }

    // MARK: - Private

    private func loadData() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([TrainingData].self, from: data) else {
            return
        }
        trainingData = decoded
    }

    private func saveData() {
        guard let encoded = try? JSONEncoder().encode(trainingData) else {
            return
        }
        try? encoded.write(to: fileURL)
    }
}
```

#### 2.2 Create ML 训练脚本

**训练步骤**：

1. 导出训练数据（CSV）
2. 使用 Create ML 应用训练模型
3. 导出 .mlmodel 文件
4. 集成到 App

**training_script.swift**（在 Mac 上运行）

```swift
import CreateML
import Foundation

// 1. 准备数据
let csvPath = "/path/to/training_data.csv"
let data = try MLDataTable(contentsOf: URL(fileURLWithPath: csvPath))

// 2. 分割数据集
let (trainingData, testingData) = data.randomSplit(by: 0.8)

// 3. 训练模型
let model = try MLTextClassifier(
    trainingData: trainingData,
    textColumn: "merchant",
    labelColumn: "category"
)

// 4. 评估模型
let evaluation = model.evaluation(on: testingData)
print("准确率: \(evaluation.classificationError)")

// 5. 导出模型
let modelURL = URL(fileURLWithPath: "/path/to/CategoryClassifier.mlmodel")
try model.write(to: modelURL)
```

#### 2.3 集成 CoreML 模型

**MLCategoryPredictor.swift**

```swift
import CoreML

class MLCategoryPredictor {
    static let shared = MLCategoryPredictor()

    private var model: CategoryClassifier?

    init() {
        // 尝试加载模型
        do {
            model = try CategoryClassifier(configuration: MLModelConfiguration())
        } catch {
            print("模型加载失败: \(error)")
        }
    }

    /// 使用 ML 模型预测分类
    func predictCategory(for merchant: String) -> String? {
        guard let model = model else {
            return nil
        }

        do {
            let prediction = try model.prediction(merchant: merchant)
            return prediction.category
        } catch {
            print("预测失败: \(error)")
            return nil
        }
    }

    /// 获取预测置信度
    func predictWithConfidence(for merchant: String) -> (category: String, confidence: Double)? {
        guard let model = model else {
            return nil
        }

        do {
            let prediction = try model.prediction(merchant: merchant)
            let confidence = prediction.categoryProbability[prediction.category] ?? 0.0
            return (prediction.category, confidence)
        } catch {
            return nil
        }
    }
}
```

#### 2.4 混合策略（规则 + ML）

**更新 CategoryEngine.swift**

```swift
func inferCategory(merchant: String?, rawText: String?) -> String {
    let text = "\(merchant ?? "") \(rawText ?? "")".lowercased()

    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return "其他"
    }

    // 1. 优先匹配用户自定义规则（最高优先级）
    if let category = matchUserRules(text: text) {
        return category
    }

    // 2. 尝试 ML 模型预测（新增）
    if let merchant = merchant,
       let prediction = MLCategoryPredictor.shared.predictWithConfidence(for: merchant),
       prediction.confidence > 0.7 {  // 置信度阈值
        return prediction.category
    }

    // 3. 匹配预设规则
    if let category = matchPresetRules(text: text) {
        return category
    }

    // 4. 正则模式匹配
    if let category = matchByPattern(text: text) {
        return category
    }

    // 5. 默认分类
    return "其他"
}
```

**预计工时**: 12-16 小时

---

### Phase 3: 本地 NLP 对话记账（10-12 小时）

#### 3.1 UI 设计

```
┌─────────────────────────────────────┐
│  智能记账                           │
├─────────────────────────────────────┤
│  说说你的消费...                    │
│  ┌───────────────────────────────┐ │
│  │                               │ │
│  │  今天中午星巴克花了35块        │ │  ← 用户输入
│  │                               │ │
│  └───────────────────────────────┘ │
│           [识别]                    │
├─────────────────────────────────────┤
│  📊 识别结果                        │
│  ┌───────────────────────────────┐ │
│  │ 金额: ¥35.00                  │ │
│  │ 商家: 星巴克                  │ │
│  │ 分类: 餐饮                    │ │
│  │ 时间: 今天 12:00              │ │
│  └───────────────────────────────┘ │
│           [确认保存]                │
└─────────────────────────────────────┘
```

#### 3.2 核心实现

**NLPParser.swift**

```swift
import NaturalLanguage

struct ParsedTransaction {
    var amount: Double?
    var merchant: String?
    var category: String?
    var time: Date?
    var type: String = "expense"  // 默认支出
    var confidence: Double = 0.0   // 识别置信度
}

class NLPParser {

    /// 解析自然语言输入
    static func parse(_ text: String) -> ParsedTransaction {
        var result = ParsedTransaction()

        // 1. 提取金额
        result.amount = extractAmount(from: text)

        // 2. 提取商家/机构名称
        result.merchant = extractMerchant(from: text)

        // 3. 提取时间
        result.time = extractTime(from: text)

        // 4. 判断收入/支出
        result.type = extractType(from: text)

        // 5. 计算置信度
        result.confidence = calculateConfidence(result)

        return result
    }

    // MARK: - 金额提取

    private static func extractAmount(from text: String) -> Double? {
        // 支持多种表达
        let patterns = [
            #"(\d+\.?\d*)[元块钱]"#,     // 35元、35块、35.5钱
            #"[花费用][了](\d+\.?\d*)"#,  // 花了35、用了35
            #"(\d+\.?\d*)[块元]"#         // 35块、35元
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountString = String(text[range])
                if let amount = Double(amountString) {
                    return amount
                }
            }
        }

        return nil
    }

    // MARK: - 商家提取（使用 NaturalLanguage）

    private static func extractMerchant(from text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var merchants: [String] = []

        // 识别机构名称
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType) { tag, range in
            if tag == .organizationName {
                merchants.append(String(text[range]))
            }
            return true
        }

        if !merchants.isEmpty {
            return merchants.first
        }

        // 降级方案：关键词匹配
        let knownMerchants = ["星巴克", "麦当劳", "肯德基", "喜茶", "奈雪", "瑞幸", "滴滴", "美团"]
        for merchant in knownMerchants {
            if text.contains(merchant) {
                return merchant
            }
        }

        return nil
    }

    // MARK: - 时间提取

    private static func extractTime(from text: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        // 时间关键词
        if text.contains("今天") || text.contains("今日") {
            return now
        }

        if text.contains("昨天") || text.contains("昨日") {
            return calendar.date(byAdding: .day, value: -1, to: now)
        }

        if text.contains("前天") {
            return calendar.date(byAdding: .day, value: -2, to: now)
        }

        // 时间段
        if text.contains("早上") || text.contains("上午") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 9
            return calendar.date(from: components)
        }

        if text.contains("中午") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 12
            return calendar.date(from: components)
        }

        if text.contains("下午") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 15
            return calendar.date(from: components)
        }

        if text.contains("晚上") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 19
            return calendar.date(from: components)
        }

        return now  // 默认当前时间
    }

    // MARK: - 类型提取

    private static func extractType(from text: String) -> String {
        // 收入关键词
        let incomeKeywords = ["收入", "工资", "奖金", "红包", "转账给我", "收到"]
        for keyword in incomeKeywords {
            if text.contains(keyword) {
                return "income"
            }
        }

        // 默认支出
        return "expense"
    }

    // MARK: - 置信度计算

    private static func calculateConfidence(_ result: ParsedTransaction) -> Double {
        var score = 0.0

        if result.amount != nil { score += 0.4 }  // 金额最重要
        if result.merchant != nil { score += 0.3 }  // 商家次之
        if result.time != nil { score += 0.2 }     // 时间
        if result.type == "expense" || result.type == "income" { score += 0.1 }

        return score
    }
}
```

**SmartInputView.swift**

```swift
struct SmartInputView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    @State private var inputText = ""
    @State private var parsedResult: ParsedTransaction?
    @State private var isParsing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text("说说你的消费...")
                        .font(.headline)

                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            Text("例如：今天中午星巴克花了35块")
                                .foregroundColor(.secondary)
                                .opacity(inputText.isEmpty ? 1 : 0)
                                .padding()
                        ,alignment: .topLeading)
                }

                // 识别按钮
                Button("智能识别") {
                    parseInput()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty || isParsing)

                // 识别结果
                if let result = parsedResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("识别结果")
                                .font(.headline)

                            Spacer()

                            Text("置信度: \(Int(result.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(result.confidence > 0.7 ? .green : .orange)
                        }

                        Group {
                            if let amount = result.amount {
                                resultRow(label: "金额", value: "¥\(String(format: "%.2f", amount))", icon: "yensign.circle.fill")
                            }

                            if let merchant = result.merchant {
                                resultRow(label: "商家", value: merchant, icon: "building.2.fill")
                            }

                            if let time = result.time {
                                resultRow(label: "时间", value: time.formatted(date: .abbreviated, time: .shortened), icon: "clock.fill")
                            }

                            resultRow(label: "类型", value: result.type == "expense" ? "支出" : "收入", icon: result.type == "expense" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        }

                        if result.confidence < 0.7 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("识别不确定，请检查并手动修正")
                                    .font(.caption)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    Button("确认保存") {
                        saveTransaction()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("智能记账")
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

    private func resultRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func parseInput() {
        isParsing = true
        HapticManager.shared.mediumImpact()

        // 模拟异步处理（实际是本地运行，很快）
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s 延迟，增加真实感

            let result = NLPParser.parse(inputText)
            parsedResult = result

            if result.confidence > 0.7 {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.warning()
            }

            isParsing = false
        }
    }

    private func saveTransaction() {
        guard let result = parsedResult,
              let amount = result.amount else {
            return
        }

        let merchant = result.merchant ?? "未知"
        let category = CategoryEngine.shared.inferCategory(merchant: merchant, rawText: nil)

        let transaction = Transaction(
            amount: amount,
            merchant: merchant,
            categoryName: category,
            type: result.type,
            paymentMethod: "智能记账",
            rawText: inputText,
            timestamp: result.time ?? Date(),
            note: nil
        )

        Task {
            do {
                try await dataManager.saveTransaction(transaction)
                HapticManager.shared.success()
                dismiss()
            } catch {
                HapticManager.shared.error()
            }
        }
    }
}
```

**预计工时**: 10-12 小时

---

## 💰 成本分析

### 零额外费用方案

| 组件 | 技术 | 成本 | 说明 |
|------|------|------|------|
| OCR | Vision Framework | **¥0** | Apple 原生，设备上运行 |
| 文本分类 | CoreML + Create ML | **¥0** | Apple 原生，本地训练和推理 |
| NLP 解析 | NaturalLanguage Framework | **¥0** | Apple 原生，设备上运行 |
| 模型训练 | Create ML | **¥0** | Mac 应用，免费 |
| 数据存储 | SwiftData | **¥0** | Apple 原生 |
| **总计** | | **¥0** | |

### 如果使用云端 API（对比）

| 服务 | 成本 | 中国可用 | 说明 |
|------|------|---------|------|
| OpenAI GPT-4 | $0.03/1K tokens | ❌ | 被墙 + 收费 |
| Google Cloud Vision | $1.50/1K images | ❌ | 被墙 + 收费 |
| Azure Cognitive | $1.00/1K txn | ✅ | 收费，月账单约 $30+ |

**结论**: 使用 Apple 原生框架，**零成本**，**完全可用**。

---

## 📋 实施顺序和时间表

### 第 1 周（6-8 小时）
**Phase 1: OCR 小票扫描**
- Day 1: OCRManager + ReceiptParser (4h)
- Day 2: ReceiptScannerView + 集成 (4h)

### 第 2-3 周（12-16 小时）
**Phase 2: CoreML 智能分类**
- Day 1-2: 数据收集和管理 (4h)
- Day 3-4: Create ML 训练 (4h)
- Day 5-6: 模型集成和测试 (4-8h)

### 第 4 周（10-12 小时）
**Phase 3: 本地 NLP 对话记账**
- Day 1-2: NLPParser 实现 (6h)
- Day 3-4: SmartInputView + 测试 (4-6h)

**总计**: 28-36 小时

---

## ✅ 验收标准

### Phase 1: OCR
- [ ] 能识别中文小票
- [ ] 准确提取金额（准确率 > 85%）
- [ ] 准确提取商家（准确率 > 70%）
- [ ] 处理速度 < 3 秒

### Phase 2: CoreML
- [ ] 模型训练成功
- [ ] 分类准确率 > 85%（测试集）
- [ ] 推理速度 < 100ms
- [ ] 降级方案正常工作

### Phase 3: NLP
- [ ] 简单语句识别率 > 80%
- [ ] 金额提取准确率 > 90%
- [ ] 商家提取准确率 > 60%
- [ ] 降级方案友好

---

## 🚀 下一步行动

1. ✅ **立即开始**: Phase 1 - OCR 小票扫描
   - 最实用
   - 无需训练数据
   - 快速见效

2. **用户使用 100 次后**: Phase 2 - CoreML 智能分类
   - 有足够训练数据
   - 准确度显著提升

3. **v2.0 版本**: Phase 3 - NLP 对话记账
   - 锦上添花
   - 增强用户体验

---

**准备开始实施 Phase 1: OCR 小票扫描 ✅**
