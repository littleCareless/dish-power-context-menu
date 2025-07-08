class TerminalConfig {
  String name;
  String type;
  String bundleId;

  TerminalConfig({
    required this.name,
    required this.type,
    required this.bundleId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'bundleId': bundleId,
  };

  factory TerminalConfig.fromJson(Map<String, dynamic> json) {
    return TerminalConfig(
      name: json['name'],
      type: json['type'],
      bundleId: json['bundleId'],
    );
  }
}