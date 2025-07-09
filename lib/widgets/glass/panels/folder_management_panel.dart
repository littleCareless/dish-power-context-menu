import 'package:flutter/material.dart';
import '../core/glass_colors.dart';
import '../core/glass_container.dart';
import '../components/glass_button.dart';
import '../components/animated_glass_list_tile.dart';

/// 文件夹管理面板组件
class FolderManagementPanel extends StatelessWidget {
  final List<String> selectedFolders;
  final VoidCallback? onClearAll;

  const FolderManagementPanel({
    super.key,
    required this.selectedFolders,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '已授权文件夹',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '管理您的文件夹访问权限',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedFolders.isNotEmpty && onClearAll != null)
                GlassButton.outlined(
                  onPressed: onClearAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 18),
                      SizedBox(width: 8),
                      Text('清空'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // 文件夹列表
          Expanded(
            child:
                selectedFolders.isEmpty
                    ? _buildEmptyState()
                    : _buildFolderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_off_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无已授权的文件夹',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '请使用左侧的操作面板选择文件夹\n开始管理您的Finder菜单',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8.0,
      radius: const Radius.circular(4),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24, right: 24),
        itemCount: selectedFolders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final folderPath = selectedFolders[index];
          String folderName = folderPath;
          if (folderPath.contains('/')) {
            final parts = folderPath.split('/').where((s) => s.isNotEmpty);
            if (parts.isNotEmpty) {
              folderName = parts.last;
            } else if (folderPath == '/') {
              folderName = '根目录';
            }
          } else if (folderPath.isEmpty) {
            folderName = '未知路径';
          }

          return AnimatedGlassListTile(
            animationDelay: index * 50,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlassColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_shared_outlined,
                color: GlassColors.accent,
                size: 24,
              ),
            ),
            title: Text(
              folderName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              folderPath,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '已授权',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}