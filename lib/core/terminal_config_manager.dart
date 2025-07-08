import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/terminal_config.dart';

class TerminalConfigManager {
  // 保存终端配置列表
  static Future<void> saveTerminalConfigs(List<TerminalConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final configList = configs.map((config) => config.toJson()).toList();
    await prefs.setString('terminalConfigs', jsonEncode(configList));
    print('Flutter: \${configs.length} terminal configs saved.');
  }

  // 加载终端配置列表
  static Future<List<TerminalConfig>> loadTerminalConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configString = prefs.getString('terminalConfigs');
    List<TerminalConfig> terminalConfigs = [];
    if (configString != null) {
      final List<dynamic> configList = jsonDecode(configString);
      terminalConfigs = configList.map((e) => TerminalConfig.fromJson(e)).toList();
      print('Flutter: \${terminalConfigs.length} terminal configs loaded.');
    } else {
      print('Flutter: No terminal configs found, using defaults.');
      // 设置默认终端配置
      terminalConfigs = [
        TerminalConfig(name: 'Terminal', type: 'terminal', bundleId: 'com.apple.Terminal'),
        TerminalConfig(name: 'iTerm2', type: 'iterm', bundleId: 'com.googlecode.iterm2'),
        TerminalConfig(name: 'Warp', type: 'warp', bundleId: 'dev.warp.Warp-Stable'),
        TerminalConfig(name: 'VSCode', type: 'vscode', bundleId: 'com.microsoft.VSCode'),
      ];
      await saveTerminalConfigs(terminalConfigs); // 保存默认配置
    }
    return terminalConfigs;
  }
}