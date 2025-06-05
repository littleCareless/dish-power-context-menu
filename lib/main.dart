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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // 建议开启 Material 3
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
          print('Flutter: openFolder returned an unexpected type: ${rawResult.runtimeType}');
        }
      }

      if (resultList.isNotEmpty) {
        List<String> currentBookmarks = await loadBookmarks() ?? [];
        List<String> newBookmarksFromSelection = [];
        List<String> newPathsFromSelection = [];

        for (var item in resultList) { // 使用 resultList 进行迭代
          if (item is Map) {
            final folderPath = item['path'] as String?;
            final bookmark = item['bookmark'] as String?;
            if (folderPath != null && bookmark != null) {
              newPathsFromSelection.add(folderPath);
              newBookmarksFromSelection.add(bookmark);
              print('Flutter: User selected folder: $folderPath');
              print('Flutter: Received bookmark: ${bookmark.substring(0, (bookmark.length < 20 ? bookmark.length : 20))}...');
            }
          }
        }

        if (newPathsFromSelection.isNotEmpty) {
          // 合并现有书签和新选择的书签，去重
          final allBookmarksSet = {...currentBookmarks, ...newBookmarksFromSelection}.toList();
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
        print('Flutter: User cancelled folder selection or no folders returned.');
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
          final List<dynamic> successfulPathsDynamic = result['successfulPaths'] ?? [];
          final List<String> successfulPaths = successfulPathsDynamic.map((e) => e.toString()).toList();
          
          final List<dynamic> failedBookmarksDynamic = result['failedBookmarks'] ?? [];
          final List<String> failedBookmarks = failedBookmarksDynamic.map((e) => e.toString()).toList();

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
          print('Flutter: Successfully restored access for paths: $successfulPaths');
          
          if (failedBookmarks.isNotEmpty) {
            print('Flutter: Failed to restore access for bookmarks: $failedBookmarks');
            // 从 SharedPreferences 中移除无效的书签
            List<String> updatedBookmarks = List.from(bookmarks);
            updatedBookmarks.removeWhere((b) => failedBookmarks.contains(b));
            await saveBookmarks(updatedBookmarks);
            print('Flutter: Removed ${failedBookmarks.length} invalid bookmarks from storage.');
          }
        } else {
           print('Flutter: resolveBookmarks returned null result.');
           setState(() {
             selectedFolders = [];
             statusMessage = '解析书签时原生方法未返回结果。';
           });
        }
      } on PlatformException catch (e) {
        print('Flutter: Failed to restore folder access: ${e.code} - ${e.message}');
        setState(() {
          selectedFolders = [];
          statusMessage = '恢复访问失败: ${e.message}';
        });
      } catch (e) {
        print('Flutter: An unexpected error occurred during restoreFolderAccess: $e');
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清除所有已存书签',
            onPressed: clearAllBookmarks,
          ),
        ],
      ),
      body: Padding( // 使用 Padding 增加一些边距
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // 从顶部开始
          crossAxisAlignment: CrossAxisAlignment.stretch, // 使子项宽度充满
          children: <Widget>[
            Text(
              '状态:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickFolder,
              child: const Text('选择文件夹并保存权限'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: restoreFolderAccess,
              child: const Text('尝试恢复已存文件夹权限'),
            ),
            const SizedBox(height: 20),
            Text(
              '当前可访问的文件夹:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded( // 使用 Expanded 使 ListView 占据剩余空间
              child: selectedFolders.isEmpty
                  ? Center(child: Text('列表为空', style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: selectedFolders.length,
                      itemBuilder: (context, index) {
                        return Card( // 使用 Card 包装每个条目
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary),
                            title: Text(selectedFolders[index]),
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
