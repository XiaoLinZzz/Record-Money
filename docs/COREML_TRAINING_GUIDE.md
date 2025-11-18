# CoreML 智能分类训练指南

## 功能概述

CoreML 智能分类功能使用机器学习自动分类交易，特点：
- 🤖 从用户行为学习
- 📊 基于用户修正历史训练
- ⚡ 离线推理，隐私安全
- 🎯 个性化分类建议
- 🔒 零成本，完全本地化

## 前提条件

### 1. 收集训练数据

在开始训练之前，需要收集足够的用户修正数据：

**最小数据量**: 100 条用户修正记录
**推荐数据量**: 300+ 条用户修正记录
**最佳数据量**: 1000+ 条用户修正记录

#### 数据收集机制

用户每次修正交易分类时，系统会自动记录：
- 商家名称（作为输入特征）
- 修正后的分类（作为标签）

```swift
// 自动记录在这些场景：
// 1. 编辑交易时修改分类
// 2. OCR 识别后修正分类
// 3. 智能输入后调整分类

CategoryEngine.shared.learnFromUserCorrection(
    merchant: "星巴克",
    correctedCategory: "餐饮"
)
```

#### 检查数据量

```swift
let count = MLTrainingDataManager.shared.getTrainingDataCount()
let stats = MLTrainingDataManager.shared.getTrainingDataStatistics()

print("已收集数据: \(count) 条")
print("完成度: \(stats.formattedCompletionPercentage)")
print("是否足够: \(stats.hasEnoughData)")
```

### 2. 导出训练数据

#### 导出为 CSV 格式（推荐）

```swift
do {
    let csvURL = try MLTrainingDataManager.shared.exportTrainingDataAsCSV()
    print("CSV 文件已导出: \(csvURL.path)")
} catch {
    print("导出失败: \(error)")
}
```

CSV 格式示例：
```csv
text,label
"星巴克","餐饮"
"麦当劳","餐饮"
"滴滴出行","交通"
"淘宝","购物"
```

#### 导出为 JSON 格式

```swift
do {
    let jsonURL = try MLTrainingDataManager.shared.exportTrainingDataAsJSON()
    print("JSON 文件已导出: \(jsonURL.path)")
} catch {
    print("导出失败: \(error)")
}
```

## 使用 Create ML 训练模型

### 步骤 1: 准备训练数据

1. 运行 App，确保收集了足够的用户修正数据
2. 导出训练数据为 CSV 文件
3. 将 CSV 文件从设备导出到 Mac（通过 Finder 文件共享或 AirDrop）

### 步骤 2: 划分数据集

将数据分为训练集和测试集（推荐 80:20）：

**训练集** (`training_data.csv`): 80% 数据，用于训练模型
**测试集** (`testing_data.csv`): 20% 数据，用于验证模型

可以使用脚本或手动分割 CSV 文件。

### 步骤 3: 打开 Create ML

1. 在 Mac 上打开 **Create ML** 应用
2. 选择 **New Document**
3. 选择 **Text Classifier** 模板

### 步骤 4: 配置训练参数

#### 基本设置
- **Name**: `CategoryClassifier`
- **Author**: 你的名字
- **Description**: 商家分类模型
- **License**: 根据需要选择

#### 数据输入
- **Training Data**: 选择 `training_data.csv`
- **Text Column**: `text`
- **Label Column**: `label`
- **Validation Split**: 自动（或手动指定 `testing_data.csv`）

#### 训练参数
- **Algorithm**: Transfer Learning（推荐）或 Maximum Entropy
- **Maximum Iterations**: 自动（或手动设置 50-100）
- **Language**: Chinese (Simplified)

### 步骤 5: 开始训练

1. 点击 **Train** 按钮
2. 等待训练完成（通常 1-5 分钟）
3. 查看训练指标：
   - **Training Accuracy**: 训练准确率（目标 >80%）
   - **Validation Accuracy**: 验证准确率（目标 >75%）

### 步骤 6: 评估模型

#### 查看混淆矩阵
- 检查哪些分类容易混淆
- 识别需要更多训练数据的分类

#### 测试预测
- 在 **Preview** 标签页测试模型
- 输入商家名称查看预测结果
- 验证置信度和准确性

### 步骤 7: 导出模型

1. 点击 **Output** 标签页
2. 选择导出位置
3. 点击 **Get** 按钮导出 `.mlmodel` 文件
4. 文件名应为：`CategoryClassifier.mlmodel`

## 集成 CoreML 模型到 App

### 方法 1: 添加到 Xcode 项目

1. 打开 Xcode 项目
2. 将 `CategoryClassifier.mlmodel` 拖入项目
3. 确保 **Target Membership** 包含主 Target
4. Xcode 会自动生成 Swift 接口

### 方法 2: 动态加载（推荐）

将模型文件放到 App 的 Documents 目录：

```swift
// 从 Mac 复制模型文件到 iOS 设备
// 通过 Finder > 设备 > 文件共享

let sourceURL = ... // 源文件路径
try MLTrainingDataManager.shared.importCoreMLModel(from: sourceURL)

// 重新加载模型
CategoryMLClassifier.shared.reloadModel()
```

## 使用 CoreML 模型

### 自动集成

模型加载后，CategoryEngine 会自动使用 ML 预测（如果置信度 >= 0.7）：

```swift
// 自动使用 ML 模型（如果可用）
let category = await CategoryEngine.shared.inferCategoryWithML(
    merchant: "星巴克",
    rawText: nil
)
print("预测分类: \(category)")
```

### 手动使用

```swift
// 直接使用 ML 分类器
if let prediction = await CategoryMLClassifier.shared.predictCategory(for: "星巴克") {
    print("分类: \(prediction.category)")
    print("置信度: \(prediction.confidence)")
}
```

### 检查模型状态

```swift
let isAvailable = CategoryMLClassifier.shared.isAvailable()
let status = CategoryEngine.shared.getMLModelStatus()

if isAvailable {
    if let info = CategoryMLClassifier.shared.getModelInfo() {
        print(info.formattedDescription)
    }
}
```

## 数据质量建议

### 1. 数据平衡性

确保每个分类都有足够的样本：

```swift
let stats = MLTrainingDataManager.shared.getTrainingDataStatistics()

for (category, count) in stats.categoryDistribution {
    print("\(category): \(count) 条")
}

if !stats.isBalanced {
    print("⚠️ 数据不平衡，某些分类样本过少")
}
```

**建议分布**:
- 每个分类至少 10 条样本
- 最大/最小比例不超过 3:1
- 常用分类可以有更多样本

### 2. 数据清洁

- 确保商家名称准确
- 避免重复记录
- 移除明显错误的修正

### 3. 持续改进

- 定期重新训练模型（每收集 100+ 新样本）
- 监控模型准确率
- 根据用户反馈调整

## 模型性能优化

### 1. 特征工程

当前模型仅使用商家名称，未来可以添加：
- 交易金额范围
- 交易时间（时段）
- 交易频率
- 历史分类

### 2. 算法选择

**Transfer Learning** (推荐):
- 利用预训练的语言模型
- 适合中文文本
- 训练速度快，准确率高

**Maximum Entropy**:
- 传统分类算法
- 适合样本较少的情况
- 可解释性强

### 3. 超参数调整

- **Iterations**: 增加可能提高准确率，但可能过拟合
- **Learning Rate**: 默认值通常最优
- **Regularization**: 防止过拟合

## 故障排除

### 问题 1: 训练准确率低 (<70%)

**可能原因**:
- 数据量不足
- 数据标签不一致
- 特征不够区分

**解决方案**:
- 收集更多训练数据
- 检查并清理错误标签
- 增加更多特征

### 问题 2: 验证准确率远低于训练准确率

**可能原因**: 过拟合

**解决方案**:
- 增加训练数据多样性
- 减少训练迭代次数
- 使用更强的正则化

### 问题 3: 某些分类预测总是错误

**可能原因**: 该分类样本太少或特征不明显

**解决方案**:
- 针对性收集该分类的更多样本
- 检查是否与其他分类混淆
- 考虑合并相似分类

### 问题 4: 模型文件加载失败

**可能原因**:
- 文件路径错误
- 模型版本不兼容
- 编译失败

**解决方案**:
```swift
// 检查文件是否存在
let modelURL = MLTrainingDataManager.shared.getCoreMLModelURL()
print("模型路径: \(modelURL.path)")
print("文件存在: \(FileManager.default.fileExists(atPath: modelURL.path))")

// 尝试重新加载
CategoryMLClassifier.shared.reloadModel()
```

## 性能基准

### 预期指标

| 指标 | 目标值 | 优秀值 |
|------|--------|--------|
| 训练准确率 | >80% | >90% |
| 验证准确率 | >75% | >85% |
| 推理速度 | <100ms | <50ms |
| 模型大小 | <5MB | <2MB |

### 实际测试

```swift
// 批量测试
let testMerchants = ["星巴克", "麦当劳", "滴滴", "淘宝"]
let predictions = await CategoryMLClassifier.shared.predictCategories(for: testMerchants)

for (merchant, category, confidence) in predictions {
    print("\(merchant) → \(category) (\(String(format: "%.2f", confidence * 100))%)")
}
```

## Create ML 进阶技巧

### 1. 使用 Create ML API（代码训练）

```python
import CreateML

# 加载数据
data = CreateML.load_data("training_data.csv")

# 创建文本分类器
classifier = CreateML.text_classifier.create(
    data,
    target="label",
    features=["text"],
    language="zh-Hans",
    max_iterations=100
)

# 保存模型
classifier.save("CategoryClassifier.mlmodel")
```

### 2. 数据增强

- 添加同义词变体
- 使用 n-gram 特征
- 包含简称和全称

### 3. 集成测试

```swift
// 创建测试套件
let testCases: [(merchant: String, expected: String)] = [
    ("星巴克", "餐饮"),
    ("滴滴出行", "交通"),
    ("淘宝网", "购物")
]

for (merchant, expected) in testCases {
    if let prediction = await CategoryMLClassifier.shared.predictCategory(for: merchant) {
        let isCorrect = prediction.category == expected
        print("\(merchant): \(isCorrect ? "✅" : "❌") (预测: \(prediction.category), 期望: \(expected))")
    }
}
```

## 相关文档

- [AI 功能总体规划](./AI_FEATURES_PLAN_CN.md)
- [OCR 小票扫描指南](./OCR_SETUP_GUIDE.md)
- [NLP 智能输入指南](./NLP_SMART_INPUT_GUIDE.md)
- [Apple Create ML 文档](https://developer.apple.com/documentation/createml)
- [CoreML 文档](https://developer.apple.com/documentation/coreml)

## 注意事项

1. **隐私**: 所有数据保存在用户设备，不上传云端
2. **成本**: 完全零成本，无需云服务
3. **离线**: 训练和推理都可以离线完成
4. **兼容性**: 需要 iOS 13+ 支持 CoreML
5. **更新**: 建议定期重新训练以提高准确率
