import 'package:shared_preferences/shared_preferences.dart';

class BookmarkManager {
  // 保存书签列表
  static Future<void> saveBookmarks(List<String> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', bookmarks);
    print('Flutter: ${bookmarks.length} bookmarks saved.');
  }

  // 加载书签列表
  static Future<List<String>?> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks');
    if (bookmarks != null && bookmarks.isNotEmpty) {
      print('Flutter: ${bookmarks.length} bookmarks loaded.');
    } else {
      print('Flutter: No bookmarks found.');
    }
    return bookmarks;
  }

  // 清除所有书签的方法
  static Future<void> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmarks'); // 移除整个列表
    print('Flutter: All bookmarks cleared.');
  }
}