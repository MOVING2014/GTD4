import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
          
          const SizedBox(height: 40),
          
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