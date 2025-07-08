# DishPowerContextMenu 发布指南

本文档介绍了如何为 macOS 构建和打包 `DishPowerContextMenu` 应用程序。

## 构建应用程序

使用以下命令构建 Flutter macOS 应用程序：

```bash
flutter build macos
```

## 创建 DMG 安装包

构建成功后，使用 `create-dmg` 工具来创建一个 `.dmg` 安装包。

```bash
create-dmg \
  --volname "DishPowerContextMenu" \
  --window-size 500 300 \
  --icon-size 128 \
  --app-drop-link 380 150 \
  "build/macos/Build/Products/Release/DishPowerContextMenu.dmg" \
  "build/macos/Build/Products/Release/DishPowerContextMenu.app"
```

这将在 `build/macos/Build/Products/Release/` 目录下生成一个名为 `DishPowerContextMenu.dmg` 的文件。