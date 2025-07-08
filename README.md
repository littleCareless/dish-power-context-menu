# DishPowerContextMenu

厌倦了在 Finder 中繁琐的文件操作？「DishPowerContextMenu」为您带来极致便捷的右键菜单体验！一键在终端或 VSCode 中打开文件/文件夹，快速复制路径，轻松创建常用文档。告别重复点击，大幅提升您的工作效率。

## 功能特性

*   **快速打开：** 一键在终端或 VSCode 中打开选定的文件或文件夹。
*   **路径复制：** 快速复制文件或文件夹的路径到剪贴板。
*   **常用文档创建：** 轻松创建常用的文档类型，如文本文件、Markdown 文件等。
*   **高度集成：** 无缝集成到 macOS Finder 右键菜单中，操作自然流畅。

## 使用方法

1.  安装 Flutter 环境。
2.  克隆此项目到本地。
3.  在项目根目录下运行 `flutter build macos` 命令构建 macOS 应用程序。
4.  将构建好的应用程序添加到 Finder 扩展中。

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

## 目录结构

```
flutter_application_1/
├── android/
├── ios/
├── lib/
│   └── main.dart
├── linux/
├── macos/
│   ├── Flutter/
│   ├── Runner/
│   └── menu/
├── test/
├── web/
├── windows/
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── devtools_options.yaml
├── pubspec.yaml
└── README.md
```

## 贡献方式

欢迎参与项目贡献！您可以：

*   提交 Issue 报告 Bug 或提出建议。
*   提交 Pull Request 修复 Bug 或添加新功能。

## 许可证

本项目采用 MIT 许可证，详情请见 [LICENSE](LICENSE) 文件。
