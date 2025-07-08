class FinderMenuItem {
  final String title;
  final String type;
  final bool enabled;
  final String group; // 新增 group 属性

  FinderMenuItem({
    required this.title,
    required this.type,
    this.enabled = true,
    required this.group, // 将 group 设为必需
  });

  FinderMenuItem copyWith({
    String? title,
    String? type,
    bool? enabled,
    String? group,
  }) {
    return FinderMenuItem(
      title: title ?? this.title,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      group: group ?? this.group,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'enabled': enabled,
      'group': group,
    };
  }

  factory FinderMenuItem.fromJson(Map<String, dynamic> json) {
    return FinderMenuItem(
      title: json['title'],
      type: json['type'],
      enabled: json['enabled'] ?? true,
      group: json['group'] ?? 'default', // 提供默认值以确保兼容性
    );
  }
}