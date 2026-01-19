import { defineConfig } from 'vitepress'

/**
 * VitePress 站点配置
 * @see https://vitepress.dev/reference/site-config
 */
export default defineConfig({
  // 站点基础信息
  title: 'EtherType',
  description: 'macOS 原生、极简、本地优先的 AI 语音输入工具',
  lang: 'zh-CN',

  // GitHub Pages 路径
  base: '/EtherType/',

  // 主题配置
  themeConfig: {
    // Logo
    logo: '/logo.svg',

    // 导航栏
    nav: [
      { text: '首页', link: '/' },
      { text: '指南', link: '/guide/getting-started' },
      { text: '路线图', link: '/roadmap' },
      { text: 'FAQ', link: '/faq' },
      {
        text: '下载',
        link: 'https://github.com/qqyule/EtherType/releases'
      }
    ],

    // 侧边栏
    sidebar: [
      {
        text: '指南',
        items: [
          { text: '快速开始', link: '/guide/getting-started' },
          { text: '安装', link: '/guide/installation' },
          { text: '快捷键', link: '/guide/shortcuts' }
        ]
      },
      {
        text: '功能',
        items: [
          { text: '模型说明', link: '/features/models' },
          { text: '隐私说明', link: '/features/privacy' }
        ]
      },
      {
        text: '即将推出',
        collapsed: true,
        items: [
          { text: '开机自启', link: '/features/autostart' },
          { text: 'Ollama 后处理', link: '/features/ollama' },
          { text: '自定义提示词', link: '/features/prompts' },
          { text: '历史记录', link: '/features/history' },
          { text: '实时转写', link: '/features/realtime' }
        ]
      },
      {
        text: '其他',
        items: [
          { text: '路线图', link: '/roadmap' },
          { text: 'FAQ', link: '/faq' }
        ]
      }
    ],

    // 社交链接
    socialLinks: [
      { icon: 'github', link: 'https://github.com/yourusername/EtherType' }
    ],

    // 页脚
    footer: {
      message: '基于 MIT 许可发布',
      copyright: '© 2026 EtherType Contributors'
    },

    // 搜索
    search: {
      provider: 'local'
    },

    // 编辑链接
    editLink: {
      pattern: 'https://github.com/yourusername/EtherType/edit/main/Docs/:path',
      text: '在 GitHub 上编辑此页面'
    },

    // 上次更新
    lastUpdated: {
      text: '最后更新于'
    },

    // 文档页脚
    docFooter: {
      prev: '上一页',
      next: '下一页'
    },

    // 大纲
    outline: {
      label: '页面导航'
    }
  },

  // Markdown 配置
  markdown: {
    lineNumbers: true
  }
})
