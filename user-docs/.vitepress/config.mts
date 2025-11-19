import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "AutoBookkeeping",
  description: "智能记账应用 - 用户手册",
  lang: 'zh-CN',

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: '/images/logo.png',

    nav: [
      { text: '首页', link: '/' },
      { text: '快速开始', link: '/getting-started/installation' },
      { text: '功能介绍', link: '/features/transactions' },
      { text: '使用教程', link: '/tutorials/quick-add' },
      { text: '常见问题', link: '/faq/general' }
    ],

    sidebar: [
      {
        text: '快速开始',
        collapsed: false,
        items: [
          { text: '下载与安装', link: '/getting-started/installation' },
          { text: '首次使用', link: '/getting-started/first-use' },
          { text: '基本概念', link: '/getting-started/basic-concepts' }
        ]
      },
      {
        text: '功能介绍',
        collapsed: false,
        items: [
          { text: '记账功能', link: '/features/transactions' },
          { text: '分类管理', link: '/features/categories' },
          { text: '统计分析', link: '/features/statistics' },
          { text: '预算管理', link: '/features/budget' },
          { text: 'AI 智能功能', link: '/features/ai-features' }
        ]
      },
      {
        text: '使用教程',
        collapsed: false,
        items: [
          { text: '快速记账', link: '/tutorials/quick-add' },
          { text: '快捷指令设置', link: '/tutorials/shortcuts-setup' },
          { text: '智能输入', link: '/tutorials/smart-input' },
          { text: '扫描小票', link: '/tutorials/scan-receipt' },
          { text: '设置预算', link: '/tutorials/set-budget' },
          { text: '自定义分类', link: '/tutorials/custom-category' }
        ]
      },
      {
        text: '高级功能',
        collapsed: true,
        items: [
          { text: '桌面小组件', link: '/advanced/widgets' },
          { text: '通知设置', link: '/advanced/notifications' },
          { text: '数据导出', link: '/advanced/data-export' },
          { text: 'iCloud 同步', link: '/advanced/icloud-sync' }
        ]
      },
      {
        text: '常见问题',
        collapsed: true,
        items: [
          { text: '通用问题', link: '/faq/general' },
          { text: '故障排除', link: '/faq/troubleshooting' },
          { text: '隐私与安全', link: '/faq/privacy' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/XiaoLinZzz/Record-Money' }
    ],

    footer: {
      message: '基于 MIT 许可发布',
      copyright: `Copyright © 2024-${new Date().getFullYear()} Lujie`
    },

    // 搜索配置
    search: {
      provider: 'local',
      options: {
        locales: {
          root: {
            translations: {
              button: {
                buttonText: '搜索文档',
                buttonAriaLabel: '搜索文档'
              },
              modal: {
                noResultsText: '无法找到相关结果',
                resetButtonTitle: '清除查询条件',
                footer: {
                  selectText: '选择',
                  navigateText: '切换'
                }
              }
            }
          }
        }
      }
    },

    // 编辑链接
    editLink: {
      pattern: 'https://github.com/XiaoLinZzz/Record-Money/edit/main/user-docs/docs/:path',
      text: '在 GitHub 上编辑此页'
    },

    // 最后更新时间
    lastUpdated: {
      text: '最后更新于',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'short'
      }
    },

    // 文档页脚
    docFooter: {
      prev: '上一页',
      next: '下一页'
    },

    // 大纲配置
    outline: {
      label: '页面导航',
      level: [2, 3]
    },

    // 返回顶部
    returnToTopLabel: '返回顶部',
    sidebarMenuLabel: '菜单',
    darkModeSwitchLabel: '主题',
    lightModeSwitchTitle: '切换到浅色模式',
    darkModeSwitchTitle: '切换到深色模式'
  },

  // 元数据
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#34C759' }],
    ['meta', { name: 'og:type', content: 'website' }],
    ['meta', { name: 'og:locale', content: 'zh-CN' }],
    ['meta', { name: 'og:site_name', content: 'AutoBookkeeping' }]
  ]
})
