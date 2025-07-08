import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../core/bookmark_manager.dart';

class FolderPicker {
  static const platform = MethodChannel('flutter_native_channel');

  // 调用原生方法选择文件夹并获取路径和书签
  static Future<void> pickFolder(
      Function(List<String>) setSelectedFolders,
      Function(String) setStatusMessage,
      List<Map<String, dynamic>> finderMenuItems) async {
    try {
      // 原生端现在返回 List<Map<String, String>>
      // 为了更稳健地处理可能的类型转换问题（例如单个元素的列表被解析为Map），先接收为 dynamic
      final dynamic rawResult = await platform.invokeMethod('openFolder', {
        'finderMenuItems': finderMenuItems,
      });
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
            'Flutter: openFolder returned an unexpected type: \${rawResult.runtimeType}',
          );
        }
      }

      if (resultList.isNotEmpty) {
        List<String> currentBookmarks = await BookmarkManager.loadBookmarks() ?? [];
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
              print('Flutter: User selected folder: \$folderPath');
              print(
                'Flutter: Received bookmark: \${bookmark.substring(0, (bookmark.length < 20 ? bookmark.length : 20))}...',
              );
            }
          }
        }

        if (newPathsFromSelection.isNotEmpty) {
          // 合并现有书签和新选择的书签，去重
          final allBookmarksSet =
              {...currentBookmarks, ...newBookmarksFromSelection}.toList();
          await BookmarkManager.saveBookmarks(allBookmarksSet);

          // 更新UI显示的路径列表 (也可以考虑只显示新选择的，或全部可访问的)
          // 这里我们先尝试恢复所有已知的，包括新添加的
          await restoreFolderAccess(setSelectedFolders, setStatusMessage, finderMenuItems); // 调用 restore 以便统一处理路径显示和访问验证
        } else {
          print('Flutter: No valid folders selected or bookmarks generated.');
          setStatusMessage('未选择有效文件夹');
        }
      } else {
        print(
          'Flutter: User cancelled folder selection or no folders returned.',
        );
        setStatusMessage('用户取消选择或未返回文件夹');
      }
    } on PlatformException catch (e) {
      print('Flutter: Failed to pick folder: \${e.code} - \${e.message}');
      setSelectedFolders([]);
      setStatusMessage('选择文件夹失败: \${e.message}');
    } catch (e) {
      print('Flutter: An unexpected error occurred during pickFolder: \$e');
      setSelectedFolders([]);
      setStatusMessage('选择文件夹时发生未知错误');
    }
  }

  // 下次启动时恢复文件夹访问权限
  static Future<void> restoreFolderAccess(
      Function(List<String>) setSelectedFolders,
      Function(String) setStatusMessage,
      List<Map<String, dynamic>> finderMenuItems) async {
    final bookmarks = await BookmarkManager.loadBookmarks();
    if (bookmarks != null && bookmarks.isNotEmpty) {
      try {
        // 调用新的原生方法 resolveBookmarks
        final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
          'resolveBookmarks',
          {
            'bookmarksBase64': bookmarks,
            'finderMenuItems': finderMenuItems,
          }, // 将书签列表作为参数传递
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

          setSelectedFolders(successfulPaths);
          if (successfulPaths.isNotEmpty) {
            var message = "已恢复 ${successfulPaths.length} 个文件夹的访问权限。";
            if (failedBookmarks.isNotEmpty) {
              message += "\n${failedBookmarks.length} 个书签无法恢复。";
            }
            setStatusMessage(message);
          } else if (failedBookmarks.isNotEmpty) {
            setStatusMessage(
                "所有 ${bookmarks.length} 个已存书签均无法恢复访问。");
          } else {
            setStatusMessage('书签已加载，但未能解析任何路径。');
          }
          print(
            'Flutter: Successfully restored access for paths: \$successfulPaths',
          );

          if (failedBookmarks.isNotEmpty) {
            print(
              'Flutter: Failed to restore access for bookmarks: \$failedBookmarks',
            );
            // 从 SharedPreferences 中移除无效的书签
            List<String> updatedBookmarks = List.from(bookmarks);
            updatedBookmarks.removeWhere((b) => failedBookmarks.contains(b));
            await BookmarkManager.saveBookmarks(updatedBookmarks);
            print(
              'Flutter: Removed \${failedBookmarks.length} invalid bookmarks from storage.',
            );
          }
        } else {
          print('Flutter: resolveBookmarks returned null result.');
          setSelectedFolders([]);
          setStatusMessage('解析书签时原生方法未返回结果。');
        }
      } on PlatformException catch (e) {
        print(
          'Flutter: Failed to restore folder access: \${e.code} - \${e.message}',
        );
        setSelectedFolders([]);
        setStatusMessage('恢复访问失败: \${e.message}');
      } catch (e) {
        print(
          'Flutter: An unexpected error occurred during restoreFolderAccess: \$e',
        );
        setSelectedFolders([]);
        setStatusMessage('恢复访问时发生未知错误');
      }
    } else {
      print('Flutter: No bookmarks found to restore.');
      setSelectedFolders([]);
      setStatusMessage('未找到书签，请选择文件夹。');
    }
  }

  // 将菜单项列表保存到 UserDefaults
  static Future<void> saveMenuItems(
      List<Map<String, dynamic>> menuItems) async {
    try {
      await platform.invokeMethod('saveMenuItems', {'menuItems': menuItems});
    } on PlatformException catch (e) {
      print("Failed to save menu items: '${e.message}'.");
    }
  }

  // 从 UserDefaults 加载菜单项列表
  static Future<List<dynamic>?> loadMenuItems() async {
    try {
      final List<dynamic>? items = await platform.invokeMethod('loadMenuItems');
      return items;
    } on PlatformException catch (e) {
      print("Failed to load menu items: '${e.message}'.");
      return null;
    }
  }

  // 调用原生方法选择应用程序
  static Future<Map<String, String>?> pickApplication() async {
    try {
      final dynamic result = await platform.invokeMethod('pickApplication');
      if (result != null && result is Map) {
        return Map<String, String>.from(result);
      }
      return null;
    } catch (e) {
      print('Error picking application: $e');
      return null;
    }
  }
}