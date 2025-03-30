import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appName = '';
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appName = packageInfo.appName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkModeCurrent = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isFollowingSystem = themeProvider.isFollowingSystem();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // App Logo
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Name
          Center(
            child: Text(
              _appName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          
          // Version
          Center(
            child: Text(
              'Version $_version ($_buildNumber)',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 显示模式设置
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '显示设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                // 跟随系统设置
                SwitchListTile(
                  title: const Text('跟随系统'),
                  subtitle: Text(
                    '使用系统深色/浅色模式设置',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  value: isFollowingSystem,
                  secondary: Icon(
                    Icons.settings_brightness,
                    color: theme.colorScheme.primary,
                  ),
                  onChanged: (bool value) {
                    if (value) {
                      // 切换到跟随系统
                      themeProvider.setThemeMode(ThemeMode.system);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已切换到跟随系统模式'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      // 如果关闭跟随系统，则根据当前显示的模式设置为明确的深色或浅色模式
                      themeProvider.setThemeMode(
                        isDarkModeCurrent ? ThemeMode.dark : ThemeMode.light
                      );
                    }
                  },
                ),
                
                // 深色模式设置 (仅当不跟随系统时可用)
                SwitchListTile(
                  title: const Text('深色模式'),
                  subtitle: Text(
                    isDarkModeCurrent ? '当前使用深色模式' : '当前使用浅色模式',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  value: isDarkModeCurrent,
                  secondary: Icon(
                    isDarkModeCurrent ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                  onChanged: isFollowingSystem 
                    ? null  // 如果跟随系统，则不可用
                    : (bool value) {
                        themeProvider.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value ? '已切换到深色模式' : '已切换到浅色模式'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                ),
                const Divider(),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // App Introduction
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '软件介绍',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '这是一款基于GTD (Getting Things Done) 方法的任务管理应用。它帮助您组织和跟踪您的任务，提高工作效率。\n\n'
              '主要功能:\n'
              '• 日历视图，查看和管理任务日程\n'
              '• 收件箱，快速记录想法和任务\n'
              '• 优先任务，关注最重要的工作\n'
              '• 项目管理，组织相关任务\n'
              '• 定期回顾，确保任务得到跟进',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Developer Info
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '开发者信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          ListTile(
            leading: Icon(Icons.email, color: theme.colorScheme.primary),
            title: const Text('联系我们'),
            subtitle: const Text('support@example.com'),
          ),
          
          ListTile(
            leading: Icon(Icons.web, color: theme.colorScheme.primary),
            title: const Text('官方网站'),
            subtitle: const Text('www.example.com'),
          ),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }
} 