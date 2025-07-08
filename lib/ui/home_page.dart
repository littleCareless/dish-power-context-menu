import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/bookmark_manager.dart';
import '../core/terminal_config_manager.dart';
import '../native/folder_picker.dart';
import '../models/terminal_config.dart';
import '../models/finder_menu_item.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> selectedFolders = [];
  String statusMessage = '尚未选择文件夹或无访问权限';
  List<TerminalConfig> terminalConfigs = [];
  late List<FinderMenuItem> finderMenuItems;

  List<FinderMenuItem> _getDefaultMenuItems() {
    return [
      // Group: app
      // FinderMenuItem(
      //   title: '打开 Dish 主应用',
      //   type: 'com.dish.main', // 使用 Bundle ID 而非固定类型
      //   group: 'app',
      // ),
      FinderMenuItem(
        title: '在 VSCode 中打开',
        type: 'com.microsoft.VSCode',
        group: 'app',
      ),

      // Group: action
      FinderMenuItem(title: '拷贝路径', type: 'copyPath', group: 'action'),
      FinderMenuItem(title: '新建文件夹', type: 'createNewFolder', group: 'action'),

      // Group: newFile (常用文件类型)
      FinderMenuItem(title: '新建 Markdown 文件', type: '.md', group: 'newFile'),
      FinderMenuItem(title: '新建文本文件', type: '.txt', group: 'newFile'),
      FinderMenuItem(title: '新建 Python 文件', type: '.py', group: 'newFile'),
      FinderMenuItem(title: '新建 JavaScript 文件', type: '.js', group: 'newFile'),
      FinderMenuItem(title: '新建 HTML 文件', type: '.html', group: 'newFile'),
      FinderMenuItem(title: '新建 CSS 文件', type: '.css', group: 'newFile'),
      FinderMenuItem(title: '新建 JSON 文件', type: '.json', group: 'newFile'),

      // Group: terminal (initially empty, user can add)
      FinderMenuItem(
        title: '在终端中打开',
        type: 'com.apple.Terminal',
        group: 'terminal',
      ),
      FinderMenuItem(
        title: '在 Warp 中打开',
        type: 'dev.warp.Warp-Stable',
        group: 'terminal',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    finderMenuItems = _getDefaultMenuItems();
    super.initState();
    restoreFolderAccess();
    loadTerminalConfigs();
    _loadFinderMenuItems();
  }

  Future<void> loadTerminalConfigs() async {
    terminalConfigs = await TerminalConfigManager.loadTerminalConfigs();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> restoreFolderAccess() async {
    await FolderPicker.restoreFolderAccess(
      (List<String> paths) {
        if (mounted) {
          setState(() {
            selectedFolders = paths;
          });
        }
      },
      (String message) {
        if (mounted) {
          setState(() {
            statusMessage = message;
          });
        }
      },
      finderMenuItems.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> clearAllBookmarks() async {
    await BookmarkManager.clearAllBookmarks();
    if (mounted) {
      setState(() {
        selectedFolders = [];
        statusMessage = '所有书签已清除，请重新选择文件夹。';
      });
    }
  }

  Future<void> pickFolder() async {
    await FolderPicker.pickFolder(
      (List<String> paths) {
        if (mounted) {
          setState(() {
            selectedFolders = paths;
          });
        }
      },
      (String message) {
        if (mounted) {
          setState(() {
            statusMessage = message;
          });
        }
      },
      finderMenuItems.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> _showTerminalConfigDialog(BuildContext context) async {
    List<FinderMenuItem> tempMenuItems =
        finderMenuItems.map((item) => item.copyWith()).toList();

    // 使用一个可空的 StateSetter
    StateSetter? dialogStateSetter;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // 将内部的 setState 赋值给外部变量
            dialogStateSetter = setState;

            const groupTitles = {
              'app': '打开方式',
              'action': '操作菜单',
              'newFile': '新建文件',
              'terminal': '终端命令',
            };

            final Map<String, List<FinderMenuItem>> groupedMenuItems = {
              for (var group in groupTitles.keys) group: [],
            };

            for (var item in tempMenuItems) {
              if (groupedMenuItems.containsKey(item.group)) {
                groupedMenuItems[item.group]!.add(item);
              }
            }

            return AlertDialog(
              title: const Text('配置 Finder 菜单项'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text('在这里配置你想要在 Finder 菜单中显示的选项。'),
                      const SizedBox(height: 16),
                      ...groupTitles.keys.map((group) {
                        final items = groupedMenuItems[group]!;
                        final bool canAdd =
                            group == 'app' ||
                            group == 'newFile' ||
                            group == 'terminal';
                        return ExpansionTile(
                          key: ValueKey(
                            group + tempMenuItems.length.toString(),
                          ), // 确保key在重置后改变
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                groupTitles[group] ?? '其他',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (canAdd)
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: '添加新项',
                                  onPressed: () {
                                    _showAddMenuItemDialog(
                                      group,
                                      tempMenuItems,
                                      setState,
                                    );
                                  },
                                ),
                            ],
                          ),
                          initiallyExpanded: true,
                          children:
                              items.map((menuItem) {
                                // 检查是否为自定义菜单项（不是默认的 Bundle ID 或固定类型）
                                final defaultBundleIds = {
                                  'com.dish.main',
                                  'com.microsoft.VSCode',
                                  'com.apple.Terminal',
                                  'dev.warp.Warp-Stable',
                                };
                                final defaultActionTypes = {
                                  'copyPath',
                                  'createNewFolder',
                                };
                                final bool isCustom =
                                    !defaultBundleIds.contains(menuItem.type) &&
                                    !defaultActionTypes.contains(
                                      menuItem.type,
                                    ) &&
                                    !menuItem.type.startsWith('newFile:');

                                return CheckboxListTile(
                                  title: Text(menuItem.title),
                                  value: menuItem.enabled,
                                  secondary:
                                      isCustom
                                          ? IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                            tooltip: '删除此项',
                                            onPressed: () {
                                              setState(() {
                                                tempMenuItems.remove(menuItem);
                                              });
                                            },
                                          )
                                          : null,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      final index = tempMenuItems.indexOf(
                                        menuItem,
                                      );
                                      if (index != -1) {
                                        tempMenuItems[index] = menuItem
                                            .copyWith(enabled: value);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('重置'),
                  onPressed: () {
                    // 使用 dialogStateSetter 来更新对话框的UI
                    dialogStateSetter?.call(() {
                      tempMenuItems = _getDefaultMenuItems();
                    });
                  },
                ),
                const SizedBox(width: 8), // 替换 Spacer 为固定间距
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('保存'),
                  onPressed: () async {
                    // 这里我们不需要 setState，因为我们是在修改主状态
                    setState(() {
                      finderMenuItems = tempMenuItems;
                    });
                    await _saveFinderMenuItems();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveFinderMenuItems() async {
    final menuItemsJson = finderMenuItems.map((item) => item.toJson()).toList();
    // 调用原生方法将配置保存到共享的 UserDefaults
    await FolderPicker.saveMenuItems(menuItemsJson);
    print('Finder 菜单项配置已通过原生模块保存');
  }

  Future<void> _loadFinderMenuItems() async {
    // 默认菜单项，作为合并的基准
    final defaultItems = _getDefaultMenuItems();

    // 调用原生方法从共享的 UserDefaults 加载配置
    final List<dynamic>? menuItemsJson = await FolderPicker.loadMenuItems();

    if (menuItemsJson != null && menuItemsJson.isNotEmpty) {
      // 如果加载成功且不为空，则进行合并
      final loadedItems =
          menuItemsJson
              .map(
                (json) =>
                    FinderMenuItem.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();

      final loadedItemTypes = loadedItems.map((item) => item.type).toSet();

      bool needsSave = false;
      // 检查是否有新的默认菜单项需要添加
      for (final defaultItem in defaultItems) {
        if (!loadedItemTypes.contains(defaultItem.type)) {
          loadedItems.add(defaultItem);
          needsSave = true;
        }
      }

      // 按预定义的组顺序排序，以确保UI显示正确
      const groupOrder = ['app', 'action', 'newFile', 'terminal'];
      loadedItems.sort((a, b) {
        final aIndex = groupOrder.indexOf(a.group);
        final bIndex = groupOrder.indexOf(b.group);
        return aIndex.compareTo(bIndex);
      });

      if (mounted) {
        setState(() {
          finderMenuItems = loadedItems;
        });
      }

      // 如果合并后有变动，则保存回原生端
      if (needsSave) {
        await _saveFinderMenuItems();
      }
    } else {
      // 如果没有已保存的配置，则将当前默认配置保存
      await _saveFinderMenuItems();
    }
  }

  Future<void> _showAddMenuItemDialog(
    String group,
    List<FinderMenuItem> menuItems, // 接收当前正在编辑的列表
    StateSetter parentStateSetter,
  ) async {
    final titleController = TextEditingController();
    final appController = TextEditingController();
    final valueController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('添加新的"${_getGroupDisplayName(group)}"'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '菜单项标题',
                    hintText: '例如：用 Chrome 打开',
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? '标题不能为空' : null,
                ),
                if (group == 'app' || group == 'terminal')
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: appController,
                          decoration: InputDecoration(
                            labelText:
                                group == 'app'
                                    ? '应用程序 Bundle ID'
                                    : '终端应用 Bundle ID',
                            hintText:
                                group == 'app'
                                    ? '例如：com.google.Chrome'
                                    : '例如：dev.warp.Warp-Stable',
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Bundle ID 不能为空'
                                      : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_open_outlined),
                        tooltip: '从 Finder 选择应用',
                        onPressed: () async {
                          final appInfo = await FolderPicker.pickApplication();
                          if (appInfo != null) {
                            final appName = appInfo['appName'] ?? '';
                            final bundleId = appInfo['bundleId'] ?? '';

                            // 将 Bundle ID 存储在 appController 中，用于后续生成 type
                            appController.text = bundleId;

                            if (titleController.text.isEmpty) {
                              if (group == 'app') {
                                titleController.text = '用 $appName 打开';
                              } else if (group == 'terminal') {
                                titleController.text = '在 $appName 中打开';
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                if (group == 'newFile')
                  TextFormField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: '文件扩展名',
                      hintText: '.md',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '内容不能为空';
                      }
                      if (!value.startsWith('.')) {
                        return '文件扩展名必须以 "." 开头';
                      }
                      return null;
                    },
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('添加'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  String type;
                  switch (group) {
                    case 'app':
                    case 'terminal':
                      // 直接使用 Bundle ID 作为 type 值
                      type = appController.text;
                      break;
                    case 'newFile':
                      type = valueController.text;
                      break;
                    default:
                      type = '';
                  }

                  final newItem = FinderMenuItem(
                    title: titleController.text,
                    type: type,
                    group: group,
                    enabled: true,
                  );
                  parentStateSetter(() {
                    menuItems.add(newItem); // 修改传入的列表
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getGroupDisplayName(String group) {
    switch (group) {
      case 'app':
        return '打开方式';
      case 'newFile':
        return '文件类型';
      case 'terminal':
        return '终端命令';
      default:
        return '项';
    }
  }

  // TODO: 将配置传递给 Finder Sync 扩展
  // 修改 FolderPicker.pickFolder 和 FolderPicker.restoreFolderAccess 函数
  // 在成功获取文件夹访问权限后，将菜单项列表传递给 Finder Sync 扩展。

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // AppBar 样式由 ThemeData.appBarTheme 控制
        title: Text(widget.title),
        actions: [
          Tooltip(
            message: '清除所有已存书签',
            child: IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: clearAllBookmarks,
              // IconButton 颜色会由 AppBar 的 IconTheme 控制
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          0,
        ), // 底部 padding 为 0，让列表滚动到底部
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 状态信息卡片
            Card(
              color: colorScheme.surfaceContainerHighest, // 更适合 M3 的背景色
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '应用状态', // 更通用的标题
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // 调整间距
            // 操作按钮
            FilledButton.icon(
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('选择并授权新文件夹'), // 更清晰的文本
              onPressed: pickFolder,
              // style 由 ThemeData.filledButtonTheme 控制
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore_page_outlined),
              label: const Text('恢复已授权文件夹'),
              onPressed: restoreFolderAccess,
              // style 由 ThemeData.outlinedButtonTheme 控制
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: const Text('配置Finder 菜单项'),
              onPressed: () {
                _showTerminalConfigDialog(context);
              },
              // style 由 ThemeData.outlinedButtonTheme 控制
            ),
            const SizedBox(height: 24),

            // 文件夹列表标题
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0), // 微调标题位置
              child: Text(
                '已授权文件夹', // 简化标题
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 文件夹列表
            Expanded(
              child:
                  selectedFolders.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_off_outlined,
                                size: 56,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无已授权的文件夹',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '请点击上方按钮选择文件夹以开始使用。',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 16.0,
                        ), // 为列表底部增加 padding
                        itemCount: selectedFolders.length,
                        itemBuilder: (context, index) {
                          final folderPath = selectedFolders[index];
                          String folderName = folderPath;
                          if (folderPath.contains('/')) {
                            final parts = folderPath
                                .split('/')
                                .where((s) => s.isNotEmpty);
                            if (parts.isNotEmpty) {
                              folderName = parts.last;
                            } else if (folderPath == '/') {
                              folderName = '根目录';
                            }
                          } else if (folderPath.isEmpty) {
                            folderName = '未知路径';
                          }

                          return Card(
                            // CardTheme 已在 MyApp 中定义
                            child: ListTile(
                              // ListTileThemeData 已在 MyApp 中定义
                              leading: Icon(
                                Icons.folder_shared_outlined, // 更合适的图标
                                size: 30,
                                color: colorScheme.primary, // 突出显示图标
                              ),
                              title: Text(
                                folderName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                folderPath,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // trailing: IconButton( // 示例：移除按钮
                              //   icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                              //   tooltip: '移除此文件夹授权',
                              //   onPressed: () {
                              //     // TODO: 实现移除单个文件夹的逻辑
                              //     // 例如：_removeBookmarkForPath(folderPath);
                              //   },
                              // ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
