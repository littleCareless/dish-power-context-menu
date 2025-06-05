import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // 用于 JSON 编解码，如果需要存储复杂对象列表（虽然这里是 List<String>，shared_preferences 直接支持）
import 'package:shared_preferences/shared_preferences.dart'; // 导入 shared_preferences

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // 例如 Teal
          brightness: Brightness.light, // 或者 .dark
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            // color 继承自 colorScheme.onSurface 或 onPrimary
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      home: const MyHomePage(title: '文件夹授权管理'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('flutter_native_channel');
  List<String> selectedFolders = []; // 用于存储和显示选择的文件夹路径列表
  String statusMessage = '尚未选择文件夹或无访问权限'; // 用于显示状态信息

  @override
  void initState() {
    super.initState();
    restoreFolderAccess(); // 启动时尝试恢复文件夹访问权限
  }

  // 保存书签列表
  Future<void> saveBookmarks(List<String> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', bookmarks); // 使用 setStringList
    print('Flutter: ${bookmarks.length} bookmarks saved.');
  }

  // 加载书签列表
  Future<List<String>?> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks'); // 使用 getStringList
    if (bookmarks != null && bookmarks.isNotEmpty) {
      print('Flutter: ${bookmarks.length} bookmarks loaded.');
    } else {
      print('Flutter: No bookmarks found.');
    }
    return bookmarks;
  }

  // 调用原生方法选择文件夹并获取路径和书签
  Future<void> pickFolder() async {
    try {
      // 原生端现在返回 List<Map<String, String>>
      // 为了更稳健地处理可能的类型转换问题（例如单个元素的列表被解析为Map），先接收为 dynamic
      final dynamic rawResult = await platform.invokeMethod('openFolder');
      List<dynamic> resultList;

      if (rawResult is List) {
        resultList = rawResult;
      } else if (rawResult is Map) {
        // 如果原生端错误地将单个元素的列表作为 Map 返回，则将其包装在列表中
        resultList = [rawResult];
      } else {
        // 如果是 null 或其他非预期类型，视为空列表处理或根据需要抛出错误
        resultList = [];
        if (rawResult != null) {
          print(
            'Flutter: openFolder returned an unexpected type: ${rawResult.runtimeType}',
          );
        }
      }

      if (resultList.isNotEmpty) {
        List<String> currentBookmarks = await loadBookmarks() ?? [];
        List<String> newBookmarksFromSelection = [];
        List<String> newPathsFromSelection = [];

        for (var item in resultList) {
          // 使用 resultList 进行迭代
          if (item is Map) {
            final folderPath = item['path'] as String?;
            final bookmark = item['bookmark'] as String?;
            if (folderPath != null && bookmark != null) {
              newPathsFromSelection.add(folderPath);
              newBookmarksFromSelection.add(bookmark);
              print('Flutter: User selected folder: $folderPath');
              print(
                'Flutter: Received bookmark: ${bookmark.substring(0, (bookmark.length < 20 ? bookmark.length : 20))}...',
              );
            }
          }
        }

        if (newPathsFromSelection.isNotEmpty) {
          // 合并现有书签和新选择的书签，去重
          final allBookmarksSet =
              {...currentBookmarks, ...newBookmarksFromSelection}.toList();
          await saveBookmarks(allBookmarksSet);

          // 更新UI显示的路径列表 (也可以考虑只显示新选择的，或全部可访问的)
          // 这里我们先尝试恢复所有已知的，包括新添加的
          await restoreFolderAccess(); // 调用 restore 以便统一处理路径显示和访问验证
        } else {
          print('Flutter: No valid folders selected or bookmarks generated.');
          setState(() {
            statusMessage = '未选择有效文件夹';
          });
        }
      } else {
        print(
          'Flutter: User cancelled folder selection or no folders returned.',
        );
        setState(() {
          // selectedFolders = []; // 清空或保持不变
          statusMessage = '用户取消选择或未返回文件夹';
        });
      }
    } on PlatformException catch (e) {
      print('Flutter: Failed to pick folder: ${e.code} - ${e.message}');
      setState(() {
        selectedFolders = [];
        statusMessage = '选择文件夹失败: ${e.message}';
      });
    } catch (e) {
      print('Flutter: An unexpected error occurred during pickFolder: $e');
      setState(() {
        selectedFolders = [];
        statusMessage = '选择文件夹时发生未知错误';
      });
    }
  }

  // 下次启动时恢复文件夹访问权限
  Future<void> restoreFolderAccess() async {
    final bookmarks = await loadBookmarks();
    if (bookmarks != null && bookmarks.isNotEmpty) {
      try {
        // 调用新的原生方法 resolveBookmarks
        final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
          'resolveBookmarks', // 注意方法名已更改
          {'bookmarks': bookmarks}, // 将书签列表作为参数传递
        );

        if (result != null) {
          final List<dynamic> successfulPathsDynamic =
              result['successfulPaths'] ?? [];
          final List<String> successfulPaths =
              successfulPathsDynamic.map((e) => e.toString()).toList();

          final List<dynamic> failedBookmarksDynamic =
              result['failedBookmarks'] ?? [];
          final List<String> failedBookmarks =
              failedBookmarksDynamic.map((e) => e.toString()).toList();

          setState(() {
            selectedFolders = successfulPaths;
            if (successfulPaths.isNotEmpty) {
              statusMessage = '已恢复 ${successfulPaths.length} 个文件夹的访问权限。';
              if (failedBookmarks.isNotEmpty) {
                statusMessage += '\n${failedBookmarks.length} 个书签无法恢复。';
              }
            } else if (failedBookmarks.isNotEmpty) {
              statusMessage = '所有 ${bookmarks.length} 个已存书签均无法恢复访问。';
            } else {
              statusMessage = '书签已加载，但未能解析任何路径。';
            }
          });
          print(
            'Flutter: Successfully restored access for paths: $successfulPaths',
          );

          if (failedBookmarks.isNotEmpty) {
            print(
              'Flutter: Failed to restore access for bookmarks: $failedBookmarks',
            );
            // 从 SharedPreferences 中移除无效的书签
            List<String> updatedBookmarks = List.from(bookmarks);
            updatedBookmarks.removeWhere((b) => failedBookmarks.contains(b));
            await saveBookmarks(updatedBookmarks);
            print(
              'Flutter: Removed ${failedBookmarks.length} invalid bookmarks from storage.',
            );
          }
        } else {
          print('Flutter: resolveBookmarks returned null result.');
          setState(() {
            selectedFolders = [];
            statusMessage = '解析书签时原生方法未返回结果。';
          });
        }
      } on PlatformException catch (e) {
        print(
          'Flutter: Failed to restore folder access: ${e.code} - ${e.message}',
        );
        setState(() {
          selectedFolders = [];
          statusMessage = '恢复访问失败: ${e.message}';
        });
      } catch (e) {
        print(
          'Flutter: An unexpected error occurred during restoreFolderAccess: $e',
        );
        setState(() {
          selectedFolders = [];
          statusMessage = '恢复访问时发生未知错误';
        });
      }
    } else {
      print('Flutter: No bookmarks found to restore.');
      setState(() {
        selectedFolders = [];
        statusMessage = '未找到书签，请选择文件夹。';
      });
    }
  }

  // (可选) 清除所有书签的方法
  Future<void> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmarks'); // 移除整个列表
    print('Flutter: All bookmarks cleared.');
    setState(() {
      selectedFolders = [];
      statusMessage = '所有书签已清除，请重新选择文件夹。';
    });
  }

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
