import 'package:flutter/services.dart';

class BookmarkManager {
  static const platform = MethodChannel('flutter_native_channel');

  // 获取授权目录列表（替代原来的 loadBookmarks）
  static Future<List<String>> getAuthorizedDirectories() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getAuthorizedDirectories');
      final List<String> directories = result.map((e) => e.toString()).toList();
      print('Flutter: 获取到 ${directories.length} 个授权目录');
      return directories;
    } on PlatformException catch (e) {
      print('Flutter: 获取授权目录失败: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      print('Flutter: 获取授权目录时发生未知错误: $e');
      return [];
    }
  }

  // 移除指定目录
  static Future<bool> removeDirectory(String path) async {
    try {
      final bool result = await platform.invokeMethod('removeAuthorizedDirectory', {'path': path});
      if (result) {
        print('Flutter: 成功移除授权目录: $path');
      } else {
        print('Flutter: 移除授权目录失败: $path');
      }
      return result;
    } on PlatformException catch (e) {
      print('Flutter: 移除授权目录失败: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Flutter: 移除授权目录时发生未知错误: $e');
      return false;
    }
  }

  // 验证和清理书签
  static Future<void> validateBookmarks() async {
    try {
      await platform.invokeMethod('validateBookmarks');
      print('Flutter: 书签验证和清理完成');
    } on PlatformException catch (e) {
      print('Flutter: 书签验证失败: ${e.code} - ${e.message}');
    } catch (e) {
      print('Flutter: 书签验证时发生未知错误: $e');
    }
  }

  // 清除所有书签
  static Future<void> clearAllBookmarks() async {
    try {
      await platform.invokeMethod('clearAllBookmarks');
      print('Flutter: 所有书签已清除');
    } on PlatformException catch (e) {
      print('Flutter: 清除书签失败: ${e.code} - ${e.message}');
    } catch (e) {
      print('Flutter: 清除书签时发生未知错误: $e');
    }
  }

  // 保持向后兼容性的方法（已弃用）
  @Deprecated('使用 getAuthorizedDirectories() 替代')
  static Future<List<String>?> loadBookmarks() async {
    final directories = await getAuthorizedDirectories();
    return directories.isEmpty ? null : directories;
  }

  // 保持向后兼容性的方法（已弃用）
  @Deprecated('书签现在由 SecurityBookmarkManager 自动管理')
  static Future<void> saveBookmarks(List<String> bookmarks) async {
    print('Flutter: saveBookmarks 方法已弃用，书签由 SecurityBookmarkManager 自动管理');
  }
}