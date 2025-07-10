import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../core/bookmark_manager.dart';

class FolderPicker {
  static const platform = MethodChannel('flutter_native_channel');
  
  // 设置方法调用处理器来监听来自原生端的消息
  static void setMethodCallHandler({
    Function(List<String>)? setSelectedFolders,
    Function(String)? setStatusMessage,
    List<Map<String, dynamic>>? finderMenuItems,
  }) {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'directoryAuthorized':
          final String? path = call.arguments['path'];
          if (path != null) {
            print('Flutter: 收到目录授权通知: $path');
            
            // 刷新文件夹访问权限列表
            if (setSelectedFolders != null && setStatusMessage != null && finderMenuItems != null) {
              await restoreFolderAccess(
                setSelectedFolders,
                setStatusMessage,
                finderMenuItems,
              );
            }
          }
          break;
        case 'getBookmarks':
          // 处理来自原生端的获取书签请求
          print('Flutter: 收到获取书签请求');
          final directories = await BookmarkManager.getAuthorizedDirectories();
          print('Flutter: 返回 ${directories.length} 个授权目录给原生端');
          return directories;
        default:
          print('Flutter: 未知的方法调用: ${call.method}');
      }
    });
  }

  // 调用原生方法选择文件夹并获取路径和书签
  static Future<void> pickFolder(
    Function(List<String>) setSelectedFolders,
    Function(String) setStatusMessage,
    List<Map<String, dynamic>> finderMenuItems,
  ) async {
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
        List<String> newPathsFromSelection = [];

        for (var item in resultList) {
          if (item is Map) {
            final folderPath = item['path'] as String?;
            if (folderPath != null) {
              newPathsFromSelection.add(folderPath);
              print('Flutter: User selected folder: \$folderPath');
            }
          }
        }

        if (newPathsFromSelection.isNotEmpty) {
          // 刷新授权目录列表
          await restoreFolderAccess(
            setSelectedFolders,
            setStatusMessage,
            finderMenuItems,
          );
        } else {
          print('Flutter: No valid folders selected.');
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

  // 恢复文件夹访问权限
  static Future<void> restoreFolderAccess(
    Function(List<String>) setSelectedFolders,
    Function(String) setStatusMessage,
    List<Map<String, dynamic>> finderMenuItems,
  ) async {
    try {
      // 获取授权目录列表
      final directories = await BookmarkManager.getAuthorizedDirectories();
      
      if (directories.isNotEmpty) {
        setSelectedFolders(directories);
        setStatusMessage('已恢复 ${directories.length} 个文件夹的访问权限。');
        print('Flutter: Successfully restored access for paths: \$directories');
      } else {
        print('Flutter: No authorized directories found.');
        setSelectedFolders([]);
        setStatusMessage('未找到授权目录，请选择文件夹。');
      }
    } on PlatformException catch (e) {
      print('Flutter: Failed to restore folder access: \${e.code} - \${e.message}');
      setSelectedFolders([]);
      setStatusMessage('恢复访问失败: \${e.message}');
    } catch (e) {
      print('Flutter: An unexpected error occurred during restoreFolderAccess: \$e');
      setSelectedFolders([]);
      setStatusMessage('恢复访问时发生未知错误: \${e.message}');
    }
  }

  // 将菜单项列表保存到 UserDefaults
  static Future<void> saveMenuItems(
    List<Map<String, dynamic>> menuItems,
  ) async {
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
