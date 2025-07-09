import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/bookmark_manager.dart';
import '../core/terminal_config_manager.dart';
import '../native/folder_picker.dart';
import '../models/terminal_config.dart';
import '../models/finder_menu_item.dart';
import '../widgets/glass/glass.dart';

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
      barrierColor: Colors.black.withOpacity(0.3),
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

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                width: 600,
                height: 700,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '配置 Finder 菜单项',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '在这里配置你想要在 Finder 菜单中显示的选项。',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...groupTitles.keys.map((group) {
                              final items = groupedMenuItems[group]!;
                              final bool canAdd =
                                  group == 'app' ||
                                  group == 'newFile' ||
                                  group == 'terminal';
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ExpansionTile(
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (canAdd)
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          tooltip: '添加新项',
                                          color: GlassColors.accent,
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
                                          title: Text(
                                            menuItem.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          value: menuItem.enabled,
                                          activeColor: GlassColors.accent,
                                          checkColor: Colors.white,
                                          secondary:
                                              isCustom
                                                  ? IconButton(
                                                    icon: const Icon(
                                                      Icons.remove_circle_outline,
                                                    ),
                                                    tooltip: '删除此项',
                                                    color: Colors.redAccent,
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
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassButton.outlined(
                          onPressed: () {
                            // 使用 dialogStateSetter 来更新对话框的UI
                            dialogStateSetter?.call(() {
                              tempMenuItems = _getDefaultMenuItems();
                            });
                          },
                          child: const Text('重置'),
                        ),
                        Row(
                          children: [
                            GlassButton.outlined(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('取消'),
                            ),
                            const SizedBox(width: 12),
                            GlassButton.filled(
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
                              child: const Text('保存'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            width: 450,
            height: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加新的"${_getGroupDisplayName(group)}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: '菜单项标题',
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                            hintText: '例如：用 Chrome 打开',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: GlassColors.accent),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty ? '标题不能为空' : null,
                        ),
                        const SizedBox(height: 16),
                        if (group == 'app' || group == 'terminal')
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: appController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText:
                                        group == 'app'
                                            ? '应用程序 Bundle ID'
                                            : '终端应用 Bundle ID',
                                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                    hintText:
                                        group == 'app'
                                            ? '例如：com.google.Chrome'
                                            : '例如：dev.warp.Warp-Stable',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: GlassColors.accent),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? 'Bundle ID 不能为空'
                                              : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GlassButton.outlined(
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
                                child: const Icon(Icons.file_open_outlined),
                              ),
                            ],
                          ),
                        if (group == 'newFile')
                          TextFormField(
                            controller: valueController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '文件扩展名',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                              hintText: '.md',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: GlassColors.accent),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
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
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlassButton.outlined(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    GlassButton.filled(
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
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            // 状态横幅
            StatusBanner(
              statusMessage: statusMessage,
              folderCount: selectedFolders.length,
            ),
            
            // 主要内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 响应式布局：宽度大于800时使用两列布局
                    final isWideScreen = constraints.maxWidth > 800;
                    
                    if (isWideScreen) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左侧操作面板
                          SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              child: _buildActionPanel(),
                            ),
                          ),
                          const SizedBox(width: 24),
                          
                          // 右侧文件夹管理面板
                          Expanded(
                            child: FolderManagementPanel(
                              selectedFolders: selectedFolders,
                              onClearAll: clearAllBookmarks,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // 小屏幕时使用单列布局
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildActionPanel(isCompact: true),
                            const SizedBox(height: 24),
                            // 使用约束高度而不是固定高度，避免溢出
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: 300,
                                maxHeight: constraints.maxHeight * 0.6, // 最大高度为可用高度的60%
                              ),
                              child: FolderManagementPanel(
                                selectedFolders: selectedFolders,
                                onClearAll: clearAllBookmarks,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建操作面板
  Widget _buildActionPanel({bool isCompact = false}) {
    final spacing = isCompact ? 12.0 : 16.0;
    
    return Column(
      children: [
        ActionCard(
          icon: Icons.create_new_folder_outlined,
          title: '添加文件夹',
          description: '选择新的文件夹进行授权，扩展您的Finder菜单功能',
          onPressed: pickFolder,
          isPrimary: true,
          isCompact: isCompact,
        ),
        SizedBox(height: spacing),
        ActionCard(
          icon: Icons.restore_page_outlined,
          title: '恢复访问',
          description: '重新获取之前已授权的文件夹访问权限',
          onPressed: restoreFolderAccess,
          isCompact: isCompact,
        ),
        SizedBox(height: spacing),
        ActionCard(
          icon: Icons.settings_outlined,
          title: '菜单配置',
          description: '自定义Finder右键菜单项，个性化您的工作流程',
          onPressed: () => _showTerminalConfigDialog(context),
          isCompact: isCompact,
        ),
      ],
    );
  }
}
