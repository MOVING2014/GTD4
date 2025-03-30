import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hideNavigationBar = false; // 默认不隐藏导航栏
  final String _themeModeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadPreferences();
  }

  // 加载所有偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载主题模式
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex <= 2) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    
    // 加载导航栏隐藏设置
    _hideNavigationBar = prefs.getBool('hideNavigationBar') ?? false;
    
    // 应用导航栏设置
    _applyNavigationBarSettings();
    
    notifyListeners();
  }

  // 更新主题设置
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
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

  // 获取导航栏隐藏状态
  bool get hideNavigationBar => _hideNavigationBar;

  // 设置导航栏隐藏状态
  Future<void> setHideNavigationBar(bool hide) async {
    if (_hideNavigationBar == hide) return;
    
    _hideNavigationBar = hide;
    
    // 应用导航栏设置
    _applyNavigationBarSettings();
    
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideNavigationBar', hide);
  }
  
  // 应用导航栏设置
  void _applyNavigationBarSettings() {
    if (_hideNavigationBar) {
      // 隐藏导航栏（沉浸式模式）
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky, 
        overlays: []
      );
    } else {
      // 显示导航栏（边缘到边缘模式）
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
      );
    }
  }
} 