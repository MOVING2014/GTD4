import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final String _themeModeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  // 初始化时加载主题设置
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeValue = prefs.getInt(_themeModeKey);
    
    if (themeModeValue != null) {
      _themeMode = ThemeMode.values[themeModeValue];
      notifyListeners();
    }
  }

  // 更新主题设置
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    
    _themeMode = mode;
    notifyListeners();
  }

  // 检查是否是深色模式
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // 检查是否正在跟随系统
  bool isFollowingSystem() {
    return _themeMode == ThemeMode.system;
  }
} 