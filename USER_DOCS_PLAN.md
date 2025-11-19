# 📚 AutoBookkeeping 用户文档系统方案

## 🎯 目标用户

**终端用户**：使用 AutoBookkeeping App 进行日常记账的普通用户

---

## 📖 推荐的开源文档系统

### 方案 1：Docusaurus（推荐）⭐⭐⭐⭐⭐

**优点**：
- ✅ Meta (Facebook) 开源，维护活跃
- ✅ 现代化 UI，React 技术栈
- ✅ 支持多语言（中文）
- ✅ 内置搜索功能
- ✅ 支持版本管理
- ✅ 移动端友好
- ✅ 部署简单（GitHub Pages, Vercel, Netlify）
- ✅ Markdown + MDX 支持

**使用场景**：
- Discord、Redux、Jest 等知名项目都在用
- 适合功能丰富的应用文档

**网站**：https://docusaurus.io

---

### 方案 2：VuePress

**优点**：
- ✅ Vue.js 官方文档系统
- ✅ 简洁优雅，性能好
- ✅ SEO 友好
- ✅ 中文支持好
- ✅ 插件生态丰富

**缺点**：
- ⚠️ 相比 Docusaurus 功能少一些

**网站**：https://vuepress.vuejs.org

---

### 方案 3：MkDocs（Material 主题）

**优点**：
- ✅ Python 生态，简单易用
- ✅ Material Design 主题非常漂亮
- ✅ 配置简单
- ✅ 适合纯文档项目

**缺点**：
- ⚠️ 交互性相对弱
- ⚠️ 需要 Python 环境

**网站**：https://www.mkdocs.org

---

### 方案 4：GitBook

**优点**：
- ✅ 界面美观，类似书籍
- ✅ 所见即所得编辑器
- ✅ 在线托管（免费版有限制）

**缺点**：
- ⚠️ 免费版功能受限
- ⚠️ 自托管需要付费

**网站**：https://www.gitbook.com

---

## 🏆 最终推荐：Docusaurus

**理由**：
1. 功能最全面，适合长期维护
2. UI 现代化，用户体验好
3. 社区活跃，问题容易解决
4. 免费部署到 GitHub Pages
5. 支持中英文文档

---

## 📋 用户文档结构（Docusaurus）

```
user-docs/
├── docs/                          # 文档内容
│   ├── intro.md                   # 介绍
│   │
│   ├── getting-started/           # 快速开始
│   │   ├── installation.md        # 下载安装
│   │   ├── first-use.md          # 首次使用
│   │   └── basic-concepts.md      # 基本概念
│   │
│   ├── features/                  # 功能介绍
│   │   ├── transactions.md        # 记账功能
│   │   ├── budget.md             # 预算管理
│   │   ├── statistics.md         # 统计分析
│   │   ├── categories.md         # 分类管理
│   │   └── ai-features.md        # AI 功能
│   │
│   ├── tutorials/                 # 使用教程
│   │   ├── quick-add.md          # 快速记账
│   │   ├── scan-receipt.md       # 扫描小票
│   │   ├── smart-input.md        # 智能输入
│   │   ├── set-budget.md         # 设置预算
│   │   └── custom-category.md    # 自定义分类
│   │
│   ├── advanced/                  # 高级功能
│   │   ├── widgets.md            # 小组件
│   │   ├── notifications.md      # 通知设置
│   │   ├── data-export.md        # 数据导出
│   │   └── ml-training.md        # ML 训练
│   │
│   └── faq/                       # 常见问题
│       ├── general.md            # 通用问题
│       ├── troubleshooting.md    # 故障排除
│       └── privacy.md            # 隐私安全
│
├── blog/                          # 博客（可选）
│   ├── 2024-11-19-v1-release.md  # 版本发布
│   └── 2024-11-20-tips.md        # 使用技巧
│
├── static/                        # 静态资源
│   ├── img/                      # 图片
│   │   ├── logo.png
│   │   ├── screenshots/          # 截图
│   │   └── tutorials/            # 教程图片
│   └── videos/                   # 视频（可选）
│
├── docusaurus.config.js          # 配置文件
├── sidebars.js                   # 侧边栏配置
└── package.json                  # 依赖管理
```

---

## 📝 文档内容规划

### 1. 快速开始（Getting Started）

**installation.md** - 下载安装
- App Store 下载方式
- 系统要求
- 存储空间需求
- 权限说明（相机、照片库）

**first-use.md** - 首次使用
- 欢迎引导页面说明
- 初始设置步骤
- 创建第一笔记录
- 界面介绍

**basic-concepts.md** - 基本概念
- 什么是交易记录
- 什么是分类
- 什么是预算
- 收入 vs 支出

---

### 2. 功能介绍（Features）

**transactions.md** - 记账功能
- 添加交易记录
- 编辑记录
- 删除记录
- 搜索和筛选
- 交易详情查看

**budget.md** - 预算管理
- 设置预算
- 查看预算进度
- 预算提醒
- 超支警告
- 预算周期（日/周/月/年）

**statistics.md** - 统计分析
- 收支趋势图
- 分类占比
- 收支对比
- 时间段选择
- 统计报表

**categories.md** - 分类管理
- 系统预设分类
- 自定义分类
- 图标选择
- 颜色选择
- 关键词设置

**ai-features.md** - AI 智能功能
- 小票扫描（OCR）
- 智能输入（NLP）
- 智能分类（ML）
- 准确度说明
- 最佳实践

---

### 3. 使用教程（Tutorials）

**quick-add.md** - 快速记账（配截图）
```markdown
# 快速记账教程

## 步骤 1：打开 App
点击主屏幕上的 AutoBookkeeping 图标

## 步骤 2：点击"+"按钮
在交易列表页面，点击右上角的"+"按钮

## 步骤 3：填写信息
- 金额：输入交易金额（必填）
- 商家：输入商家名称
- 分类：选择交易分类
- 时间：选择交易时间

## 步骤 4：保存
点击"保存"按钮完成记录

💡 **小贴士**：使用智能输入功能，直接说"今天午饭花了35块"！
```

**scan-receipt.md** - 扫描小票（配视频/GIF）
**smart-input.md** - 智能输入
**set-budget.md** - 设置预算
**custom-category.md** - 自定义分类

---

### 4. 高级功能（Advanced）

**widgets.md** - 桌面小组件
- 添加小组件到主屏幕
- 今日支出小组件
- 预算进度小组件
- 快速记账小组件
- 调整小组件尺寸

**notifications.md** - 通知设置
- 开启/关闭通知
- 预算提醒
- 每日记账提醒
- 通知时间设置

---

### 5. 常见问题（FAQ）

**general.md** - 通用问题
```markdown
# 常见问题

## Q: 数据存储在哪里？
A: 所有数据都存储在你的 iPhone 本地，使用 Apple 的 SwiftData
技术加密保存，不会上传到云端。

## Q: 是否需要联网？
A: 不需要！AutoBookkeeping 完全离线运行，所有 AI 功能都在
本地处理。

## Q: 支持多账户吗？
A: 当前版本暂不支持多账户，所有记录在一个账户下管理。

## Q: 如何备份数据？
A: 使用 iPhone 的 iCloud 备份功能，App 数据会自动备份。
```

---

## 🎨 UI/UX 设计要点

### 文档网站特点
1. **主题色**：使用 App 的绿色主题（#34C759）
2. **Logo**：使用 App Icon
3. **截图**：真实设备截图，带设备边框
4. **导航**：清晰的侧边栏导航
5. **搜索**：全文搜索功能
6. **面包屑**：显示当前位置

### 内容风格
- 📱 简洁易懂，避免技术术语
- 🖼️ 大量使用截图和 GIF
- 💡 使用提示框（Tip、Warning、Info）
- ✅ 步骤式教程（Step 1, 2, 3...）
- 🎯 每个页面有明确的目标

---

## 🚀 快速开始（Docusaurus 实施）

### 安装 Docusaurus

```bash
# 在项目根目录创建文档目录
npx create-docusaurus@latest user-docs classic

# 进入文档目录
cd user-docs

# 启动开发服务器
npm start
```

### 配置中文

```javascript
// docusaurus.config.js
module.exports = {
  title: 'AutoBookkeeping 用户手册',
  tagline: '智能记账，轻松管理',
  url: 'https://yourusername.github.io',
  baseUrl: '/AutoBookkeeping/',

  i18n: {
    defaultLocale: 'zh-CN',
    locales: ['zh-CN'],
  },

  themeConfig: {
    navbar: {
      title: 'AutoBookkeeping',
      logo: {
        alt: 'Logo',
        src: 'img/logo.png',
      },
      items: [
        {
          type: 'doc',
          docId: 'intro',
          position: 'left',
          label: '文档',
        },
        {to: '/blog', label: '博客', position: 'left'},
        {
          href: 'https://github.com/yourusername/AutoBookkeeping',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },

    footer: {
      style: 'dark',
      copyright: `Copyright © ${new Date().getFullYear()} AutoBookkeeping`,
    },
  },
};
```

### 部署到 GitHub Pages

```bash
# 配置部署
npm run build

# 部署到 GitHub Pages
GIT_USER=<Your GitHub username> npm run deploy
```

---

## 📊 内容创建优先级

### 第一阶段（核心文档）
1. ✅ 介绍页面（intro.md）
2. ✅ 快速开始（getting-started/）
3. ✅ 基础功能介绍（features/transactions.md）
4. ✅ 常见问题（faq/general.md）

### 第二阶段（完善功能）
5. ✅ 所有功能详细说明
6. ✅ 使用教程（配截图）
7. ✅ 高级功能说明

### 第三阶段（增强内容）
8. ✅ 视频教程
9. ✅ 博客文章
10. ✅ 更新日志

---

## 🎬 截图和媒体准备

### 需要的截图（iPhone 截图）
- 📱 主界面（交易列表）
- ➕ 添加交易页面
- 📊 统计分析页面
- 💰 预算管理页面
- ⚙️ 设置页面
- 🎨 分类管理页面
- 📸 小票扫描界面
- 💬 智能输入界面

### GIF 动画（可选）
- 快速记账流程
- 扫描小票流程
- 智能输入演示
- 设置预算流程

### 工具推荐
- **截图**：iPhone 自带截图
- **设备边框**：https://mockuphone.com
- **GIF 录制**：Screen2Gif, LICEcap
- **图片压缩**：TinyPNG

---

## 💰 成本分析

### 免费方案
- **托管**：GitHub Pages（免费）
- **域名**：GitHub 子域名（免费）
- **构建**：GitHub Actions（免费）
- **总成本**：¥0

### 付费方案（可选）
- **自定义域名**：¥50-100/年
- **CDN 加速**：根据流量
- **视频托管**：YouTube（免费）或 Vimeo

---

## 📈 SEO 优化

Docusaurus 内置 SEO 支持：
- ✅ 自动生成 sitemap.xml
- ✅ Meta 标签优化
- ✅ Open Graph 支持
- ✅ 移动端适配
- ✅ 页面加载优化

---

## 🔄 维护计划

### 定期更新
- 📝 每次版本更新同步文档
- 🐛 收集用户反馈改进文档
- 📊 分析文档访问数据
- 🆕 添加新功能教程

### 社区互动
- 💬 在文档底部添加评论功能（Disqus）
- 📧 提供反馈邮箱
- 🔗 链接到社交媒体

---

## ✅ 实施清单

- [ ] 安装 Docusaurus
- [ ] 配置中文和主题
- [ ] 准备 App 截图
- [ ] 编写核心文档
- [ ] 创建使用教程
- [ ] 添加 FAQ
- [ ] 部署到 GitHub Pages
- [ ] 配置自定义域名（可选）
- [ ] SEO 优化
- [ ] 宣传推广

---

## 🌟 参考示例

优秀的用户文档网站：
- **Notion**: https://www.notion.so/help
- **Discord**: https://support.discord.com
- **Spotify**: https://support.spotify.com
- **1Password**: https://support.1password.com

---

**下一步**：我可以帮你：
1. 创建 Docusaurus 初始结构
2. 编写第一批核心文档（intro, getting-started）
3. 配置部署脚本
4. 提供完整的文档写作模板

需要我开始创建吗？
