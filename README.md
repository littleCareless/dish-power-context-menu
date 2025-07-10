# DishPowerContextMenu

厌倦了在 Finder 中繁琐的文件操作？「DishPowerContextMenu」为您带来极致便捷的右键菜单体验！一键在终端或 VSCode 中打开文件/文件夹，快速复制路径，轻松创建常用文档。基于 macOS Security-Scoped Bookmarks 的安全权限管理系统，确保您的文件访问既便捷又安全。告别重复点击，大幅提升您的工作效率。

## 功能特性

### 🚀 核心功能
*   **智能应用启动：** 支持在 Terminal、iTerm2、Warp、VSCode 等多种应用中打开文件/文件夹
*   **文件夹权限管理：** 基于 Security-Scoped Bookmarks 的智能权限系统，安全管理文件夹访问权限
*   **快捷操作：** 一键复制路径、创建新文件夹等常用操作
*   **文档快速创建：** 支持创建多种文件类型（文本、Markdown、代码文件等）
*   **自定义终端配置：** 支持添加和管理多种终端应用，包括自定义 Bundle ID
*   **动态菜单配置：** 支持分组管理菜单项，可自定义启用/禁用状态

### 🎨 用户界面
*   **现代化玻璃态设计：** 采用 Glassmorphism 设计风格，界面美观现代
*   **响应式布局：** 自适应不同屏幕尺寸，提供最佳用户体验
*   **动画效果：** 流畅的过渡动画和交互反馈
*   **直观的配置界面：** 可视化的菜单项管理和配置

### 🔧 高级特性
*   **Security-Scoped Bookmarks 系统：** 采用 macOS 原生安全机制，确保沙盒环境下的安全文件访问
*   **智能权限恢复：** 自动检测和恢复失效的文件夹访问权限，无需重复授权
*   **跨进程通信：** Flutter 主应用与 Finder 扩展间的高效消息传递机制
*   **配置持久化：** 使用 SharedPreferences 和 UserDefaults 双重保存用户配置
*   **菜单项分组管理：** 支持 app、action、newFile、terminal 四种类型的菜单项分组
*   **模块化架构：** 清晰的代码结构，易于维护和扩展

## 使用方法

### 📱 应用使用
1. **文件夹授权：** 首次使用时，点击「选择文件夹」按钮授权需要管理的文件夹
   - 系统会弹出文件夹选择对话框
   - 选择需要管理的文件夹后，应用会自动创建 Security-Scoped Bookmark
   - 授权信息会安全保存，重启应用后自动恢复
2. **配置菜单：** 点击「配置 Finder 菜单」自定义右键菜单项
   - 支持启用/禁用特定菜单项
   - 可按类型分组管理（应用、操作、新建文件、终端）
3. **添加应用：** 在配置界面中可以添加自定义的应用程序到菜单
   - 支持自定义应用名称和 Bundle ID
   - 特别支持各种终端应用的配置
4. **管理权限：** 在主界面查看和管理已授权的文件夹
   - 可以移除不再需要的文件夹权限
   - 自动检测权限状态，失效时提示重新授权

### 🎯 Finder 集成
- 在 Finder 中右键点击文件或文件夹
- 对于未授权的文件夹，会显示「添加到授权列表」选项
- 对于已授权的文件夹，显示完整的自定义菜单
- 选择相应的菜单项快速执行操作
- 支持批量选择和操作

### 🔧 故障排除
- **权限失效：** 如果菜单不显示，请检查文件夹是否已授权
- **扩展未启用：** 在系统偏好设置 > 扩展 > Finder 中启用扩展
- **权限恢复：** 应用会自动尝试恢复失效的权限，如失败请重新授权

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
│   │   ├── bookmark_manager.dart # Security-Scoped Bookmarks 管理
│   │   └── terminal_config_manager.dart # 终端配置管理
│   ├── models/                  # 数据模型
│   │   └── finder_menu_item.dart # Finder菜单项模型（支持分组）
│   ├── native/                  # 原生平台交互
│   │   └── folder_picker.dart   # 文件夹选择器（MethodChannel）
│   ├── ui/                      # 用户界面
│   │   └── home_page.dart       # 主页面（权限管理+菜单配置）
│   ├── widgets/                 # 自定义组件
│   │   └── glass/               # 玻璃态UI组件
│   │       ├── components/      # 基础组件
│   │       ├── core/           # 核心样式
│   │       └── panels/         # 面板组件
│   └── main.dart               # 应用入口
├── macos/                      # macOS 原生代码
│   ├── FinderSyncExt/          # Finder 扩展
│   │   ├── FinderSync.swift    # 扩展主文件（权限检查+菜单构建）
│   │   ├── MenuItemProvider.swift # 菜单项提供器
│   │   ├── MenuBuilder.swift   # 菜单构建器
│   │   └── ActionDispatcher.swift # 动作分发器
│   ├── Runner/                 # Flutter 主应用
│   │   ├── FinderActionHandler.swift # Finder操作处理
│   │   ├── BookmarkHandler.swift # 书签处理
│   │   └── Messager.swift      # 跨进程消息传递
│   └── Shared/                 # 共享组件
└── pubspec.yaml               # 项目配置
```

### 🏗️ 技术架构

- **Flutter 前端：** 使用 Flutter 构建现代化的玻璃态用户界面
- **Finder 扩展：** Swift 实现的 macOS FinderSync 扩展，提供右键菜单集成
- **跨进程通信：** 基于 MethodChannel 和 Messager 的 Flutter ↔ Swift 双向通信
- **权限管理：** Security-Scoped Bookmarks + BookmarkHandler 的安全访问机制
- **菜单系统：** MenuBuilder + MenuItemProvider 的动态菜单构建
- **动作分发：** ActionDispatcher + FinderActionHandler 的统一操作处理
- **数据持久化：** SharedPreferences (Flutter) + UserDefaults (macOS) 双重存储
- **模块化设计：** 清晰的分层架构，便于维护和扩展

## 技术特性

### 🔒 安全性
- **Security-Scoped Bookmarks：** 基于 macOS 原生安全机制的文件访问控制
- **沙盒兼容：** 完全兼容 macOS 应用沙盒环境的安全限制
- **权限验证：** 实时检测和验证文件夹访问权限状态
- **本地存储：** 用户数据完全本地存储，保护隐私安全

### ⚡ 性能优化
- **异步操作：** 所有文件操作均采用异步处理，避免界面卡顿
- **智能缓存：** 权限状态缓存和自动恢复机制
- **高效通信：** 优化的跨进程消息传递，减少通信开销
- **UI 优化：** 玻璃态效果和动画的性能优化

### 🔧 开发特性
- **跨进程架构：** Flutter 主应用与 Finder 扩展的解耦设计
- **消息传递系统：** 统一的 Messager 机制处理应用间通信
- **模块化架构：** 清晰的组件分离和依赖管理
- **类型安全：** Swift 和 Dart 的强类型数据模型
- **错误处理：** 完整的异常捕获和用户友好的错误提示

## 系统要求

### 运行环境
- macOS 10.15 (Catalina) 或更高版本
- 支持 Security-Scoped Bookmarks 的 macOS 系统

### 开发环境
- Xcode 12.0 或更高版本
- Flutter 3.7.2 或更高版本
- Swift 5.0 或更高版本

### 依赖项
- **Flutter 依赖：**
  - `cupertino_icons: ^1.0.8` - iOS 风格图标
  - `shared_preferences: ^2.5.3` - 本地数据存储
- **系统要求：**
  - macOS FinderSync 扩展支持
  - 文件系统访问权限

## 贡献方式

欢迎参与项目贡献！您可以：

*   提交 Issue 报告 Bug 或提出建议
*   提交 Pull Request 修复 Bug 或添加新功能
*   改进文档和代码注释
*   分享使用经验和最佳实践

## 许可证

本项目采用 MIT 许可证，详情请见 [LICENSE](LICENSE) 文件。
