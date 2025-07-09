# DishPowerContextMenu

厌倦了在 Finder 中繁琐的文件操作？「DishPowerContextMenu」为您带来极致便捷的右键菜单体验！一键在终端或 VSCode 中打开文件/文件夹，快速复制路径，轻松创建常用文档。告别重复点击，大幅提升您的工作效率。

## 功能特性

### 🚀 核心功能
*   **智能应用启动：** 支持在 Terminal、VSCode、Warp 等多种应用中打开文件/文件夹
*   **快捷操作：** 一键复制路径、创建新文件夹等常用操作
*   **文档快速创建：** 支持创建多种文件类型（文本、Markdown、代码文件等）
*   **自定义终端配置：** 支持添加和管理多种终端应用

### 🎨 用户界面
*   **现代化玻璃态设计：** 采用 Glassmorphism 设计风格，界面美观现代
*   **响应式布局：** 自适应不同屏幕尺寸，提供最佳用户体验
*   **动画效果：** 流畅的过渡动画和交互反馈
*   **直观的配置界面：** 可视化的菜单项管理和配置

### 🔧 高级特性
*   **文件夹权限管理：** 智能的文件夹访问权限管理和恢复
*   **配置持久化：** 使用 SharedPreferences 和 UserDefaults 保存用户配置
*   **安全书签系统：** 基于 macOS Security-Scoped Bookmarks 的安全访问机制
*   **模块化架构：** 清晰的代码结构，易于维护和扩展

## 使用方法

### 📱 应用使用
1. **文件夹授权：** 首次使用时，点击「选择文件夹」按钮授权需要管理的文件夹
2. **配置菜单：** 点击「配置 Finder 菜单」自定义右键菜单项
3. **添加应用：** 在配置界面中可以添加自定义的应用程序到菜单
4. **管理权限：** 在主界面查看和管理已授权的文件夹

### 🎯 Finder 集成
- 在 Finder 中右键点击文件或文件夹
- 选择相应的菜单项快速执行操作
- 支持批量选择和操作

## 安装步骤

1.  **安装 Flutter:**

    *   访问 [Flutter 官网](https://flutter.dev/docs/get-started/install) 下载并安装 Flutter SDK。
    *   配置 Flutter 环境变量。
2.  **克隆项目:**

    ```bash
    git clone https://github.com/your-username/dish-power-context-menu.git
    cd dish-power-context-menu
    ```
3.  **构建 macOS 应用程序:**

    ```bash
    flutter build macos
    ```

    构建完成后，应用程序位于 `macos/build/macos/Build/Products/Release/` 目录下。
4.  **添加到 Finder 扩展:**

    *   打开 "系统偏好设置" -> "扩展" -> "Finder"。
    *   勾选 "DishPowerContextMenu" 扩展。

## 项目架构

### 📁 目录结构

```
flutter_application_1/
├── lib/
│   ├── core/                    # 核心业务逻辑
│   │   ├── bookmark_manager.dart # 书签管理
│   │   └── terminal_config_manager.dart # 终端配置管理
│   ├── models/                  # 数据模型
│   │   ├── finder_menu_item.dart # Finder菜单项模型
│   │   └── terminal_config.dart  # 终端配置模型
│   ├── native/                  # 原生平台交互
│   │   └── folder_picker.dart   # 文件夹选择器
│   ├── ui/                      # 用户界面
│   │   └── home_page.dart       # 主页面
│   ├── widgets/                 # 自定义组件
│   │   └── glass/               # 玻璃态UI组件
│   │       ├── components/      # 基础组件
│   │       ├── core/           # 核心样式
│   │       └── panels/         # 面板组件
│   └── main.dart               # 应用入口
├── macos/                      # macOS 原生代码
│   ├── FinderSyncExt/          # Finder 扩展
│   │   ├── FinderSync/         # 核心同步逻辑
│   │   └── FinderSync.swift    # 扩展主文件
│   ├── Handlers/               # 业务处理器
│   │   ├── BookmarkHandler.swift # 书签处理
│   │   ├── FinderActionHandler.swift # Finder操作处理
│   │   └── MenuConfigHandler.swift # 菜单配置处理
│   ├── Runner/                 # Flutter 主应用
│   └── Shared/                 # 共享组件
└── pubspec.yaml               # 项目配置
```

### 🏗️ 技术架构

- **Flutter 前端：** 使用 Flutter 构建现代化的用户界面
- **原生 macOS 集成：** Swift 实现的 Finder 扩展和系统级功能
- **数据持久化：** SharedPreferences (Flutter) + UserDefaults (macOS)
- **安全访问：** macOS Security-Scoped Bookmarks 机制
- **模块化设计：** 清晰的分层架构，便于维护和扩展

## 技术特性

### 🔒 安全性
- 基于 macOS Security-Scoped Bookmarks 的安全文件访问
- 沙盒环境下的安全权限管理
- 用户数据本地存储，保护隐私

### ⚡ 性能优化
- 异步文件操作，避免界面卡顿
- 智能的权限缓存和恢复机制
- 优化的 UI 渲染和动画性能

### 🔧 开发特性
- 完整的错误处理和日志记录
- 模块化的代码架构
- 类型安全的数据模型
- 原生平台的深度集成

## 系统要求

- macOS 10.15 或更高版本
- Xcode 12.0 或更高版本（开发）
- Flutter 3.7.2 或更高版本（开发）

## 贡献方式

欢迎参与项目贡献！您可以：

*   提交 Issue 报告 Bug 或提出建议
*   提交 Pull Request 修复 Bug 或添加新功能
*   改进文档和代码注释
*   分享使用经验和最佳实践

## 许可证

本项目采用 MIT 许可证，详情请见 [LICENSE](LICENSE) 文件。
