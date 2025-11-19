# AutoBookkeeping 用户文档

这是 [AutoBookkeeping](https://github.com/XiaoLinZzz/Record-Money) 的用户文档站点，基于 [VitePress](https://vitepress.dev/) 构建。

## 📚 文档结构

```
docs/
├── index.md                    # 首页
├── getting-started/            # 快速开始
│   ├── installation.md         # 下载与安装
│   ├── first-use.md           # 首次使用
│   └── basic-concepts.md      # 基本概念
├── features/                   # 功能介绍
│   ├── transactions.md         # 记账功能
│   ├── categories.md          # 分类管理
│   ├── statistics.md          # 统计分析
│   ├── budget.md              # 预算管理
│   └── ai-features.md         # AI 智能功能
├── tutorials/                  # 使用教程
│   ├── quick-add.md           # 快速记账
│   ├── shortcuts-setup.md     # 快捷指令设置
│   ├── smart-input.md         # 智能输入
│   ├── scan-receipt.md        # 扫描小票
│   ├── set-budget.md          # 设置预算
│   └── custom-category.md     # 自定义分类
├── advanced/                   # 高级功能
│   ├── widgets.md             # 桌面小组件
│   ├── notifications.md       # 通知设置
│   ├── data-export.md         # 数据导出
│   └── icloud-sync.md         # iCloud 同步
└── faq/                        # 常见问题
    ├── general.md             # 通用问题
    ├── troubleshooting.md     # 故障排除
    └── privacy.md             # 隐私与安全
```

## 🚀 快速开始

### 安装依赖

```bash
npm install
```

### 本地开发

```bash
npm run docs:dev
```

文档站点将运行在 `http://localhost:5173`

### 构建生产版本

```bash
npm run docs:build
```

构建产物位于 `docs/.vitepress/dist/`

### 预览生产版本

```bash
npm run docs:preview
```

## 📝 编写文档

### Markdown 语法

VitePress 支持完整的 Markdown 语法，以及一些扩展功能：

#### 自定义容器

```markdown
::: tip 提示
这是一个提示
:::

::: warning 警告
这是一个警告
:::

::: danger 危险
这是一个危险提示
:::

::: info 信息
这是一个信息提示
:::

::: details 点击展开
这是可折叠的内容
:::
```

#### 代码块

````markdown
```javascript
const hello = 'world'
```

```javascript{1,3-5}
// 高亮第 1 行和第 3-5 行
const hello = 'world'
console.log(hello)
// 更多代码
// ...
```
````

#### 表格

```markdown
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| 内容 | 内容 | 内容 |
```

### 添加新页面

1. 在对应目录创建 `.md` 文件
2. 添加 frontmatter（可选）：

```markdown
---
title: 页面标题
description: 页面描述
---

# 页面内容
```

3. 在 `.vitepress/config.mts` 的 `sidebar` 中添加链接

### 添加图片

1. 将图片放在 `public/images/` 目录
2. 在文档中引用：

```markdown
![图片描述](/images/screenshot.png)
```

## 🎨 自定义样式

### 全局样式

在 `.vitepress/theme/custom.css` 中添加自定义 CSS

### 组件样式

在 Markdown 文件中使用 `<style scoped>` 标签：

```vue
<style scoped>
.custom-class {
  color: #42b983;
}
</style>
```

## 🚢 部署

### GitHub Pages

1. 在 `.vitepress/config.mts` 中设置 `base`：

```typescript
export default defineConfig({
  base: '/Record-Money/',  // 仓库名
  // ...
})
```

2. 创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy VitePress site to Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm ci
        working-directory: ./user-docs
      - run: npm run docs:build
        working-directory: ./user-docs
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./user-docs/docs/.vitepress/dist
```

3. 推送到 GitHub
4. 在仓库设置中启用 GitHub Pages

### Netlify / Vercel

直接连接 GitHub 仓库，设置：

- **Build Command**: `npm run docs:build`
- **Publish Directory**: `docs/.vitepress/dist`
- **Working Directory**: `user-docs`

## 📖 文档写作指南

### 内容原则

1. **用户友好**：使用简单易懂的语言，避免技术术语
2. **结构清晰**：使用标题、列表、表格组织内容
3. **示例丰富**：提供实际的使用示例和截图
4. **保持更新**：随着功能更新及时更新文档

### 格式规范

- 使用中文标点符号
- 代码使用反引号包裹
- 重要内容使用加粗
- 链接使用相对路径
- 截图添加描述性 alt 文本

### 文档模板

#### 功能介绍页面

```markdown
# 功能名称

简要介绍这个功能是什么。

## 为什么需要这个功能

解释功能的价值和使用场景。

## 如何使用

详细的使用步骤。

## 常见问题

针对这个功能的常见问题。

## 相关阅读

链接到相关文档。
```

#### 教程页面

```markdown
# 教程标题

## 学习目标

完成本教程后，你将能够...

## 前置条件

开始之前，请确保...

## 步骤 1

详细说明...

## 步骤 2

详细说明...

## 总结

回顾要点...

## 下一步

继续学习...
```

## 🔍 SEO 优化

每个页面添加 frontmatter：

```yaml
---
title: 页面标题
description: 页面描述（用于搜索引擎）
head:
  - - meta
    - name: keywords
      content: 关键词1, 关键词2
---
```

## 📊 文档统计

使用以下脚本统计文档情况：

```bash
# 统计文档数量
find docs -name "*.md" | wc -l

# 统计总字数
find docs -name "*.md" -exec wc -m {} + | tail -1
```

## 🤝 贡献指南

欢迎贡献文档！

1. Fork 本仓库
2. 创建分支：`git checkout -b docs/your-topic`
3. 编写或修改文档
4. 提交更改：`git commit -m 'docs: add xxx'`
5. 推送分支：`git push origin docs/your-topic`
6. 创建 Pull Request

### 贡献检查清单

- [ ] 拼写检查
- [ ] 语法正确
- [ ] 代码示例可运行
- [ ] 截图清晰（如果有）
- [ ] 链接有效
- [ ] 格式统一

## 📝 待完成文档

- [ ] features/categories.md
- [ ] features/statistics.md
- [ ] features/budget.md
- [ ] features/ai-features.md
- [ ] tutorials/shortcuts-setup.md
- [ ] tutorials/smart-input.md
- [ ] tutorials/scan-receipt.md
- [ ] tutorials/set-budget.md
- [ ] tutorials/custom-category.md
- [ ] advanced/widgets.md
- [ ] advanced/notifications.md
- [ ] advanced/data-export.md
- [ ] advanced/icloud-sync.md
- [ ] faq/troubleshooting.md
- [ ] faq/privacy.md

## 📚 资源

- [VitePress 官方文档](https://vitepress.dev/)
- [Markdown 语法指南](https://www.markdownguide.org/)
- [AutoBookkeeping GitHub](https://github.com/XiaoLinZzz/Record-Money)

## 📄 许可证

本文档采用 [MIT 许可证](../LICENSE)

---

**Made with ❤️ by Lujie**
