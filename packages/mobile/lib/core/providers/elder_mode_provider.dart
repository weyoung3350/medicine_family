import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 适老化模式状态管理。
/// 开启后首页直接显示极简大字打卡界面，减少操作步骤。
class ElderModeProvider extends ChangeNotifier {
  static const _key = 'elder_mode';
  bool _enabled = false;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get loaded => _loaded;

  ElderModeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _enabled = !_enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _enabled);
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
  }
}
