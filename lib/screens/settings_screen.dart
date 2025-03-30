import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/backup_helper.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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
    
    // 定义一个通用的模块标题样式
    TextStyle sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // App Logo 和基础信息
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
                Text(
                  '显示设置',
                  style: sectionTitleStyle,
                ),
                const SizedBox(height: 10),
                
                // 跟随系统设置
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: SwitchListTile(
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
                ),
                
                // 深色模式设置 (仅当不跟随系统时可用)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: SwitchListTile(
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
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 数据备份与恢复
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '数据备份与恢复',
                  style: sectionTitleStyle,
                ),
                const SizedBox(height: 10),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.upload_file, color: theme.colorScheme.primary),
                    title: const Text('导出数据'),
                    subtitle: const Text('将所有任务和项目导出为CSV文件'),
                    onTap: () async {
                      final result = await BackupHelper.exportData(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.success
                                ? '数据导出成功: ${result.message}'
                                : '导出失败: ${result.message}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.download_rounded, color: theme.colorScheme.primary),
                    title: const Text('导入数据'),
                    subtitle: const Text('从CSV文件导入任务和项目'),
                    onTap: () async {
                      // Show confirmation dialog before import
                      final shouldImport = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('导入数据'),
                          content: const Text('导入数据将覆盖现有数据，确定要继续吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldImport == true && context.mounted) {
                        final result = await BackupHelper.importData(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.success 
                                  ? '数据导入成功: ${result.message}'
                                  : '导入失败: ${result.message}'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    '数据库备份',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.storage, color: theme.colorScheme.primary),
                    title: const Text('导出数据库'),
                    subtitle: const Text('导出整个数据库文件，用于完整备份'),
                    onTap: () async {
                      final result = await BackupHelper.exportDatabase(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.success
                                ? '数据库导出成功: ${result.message}'
                                : '导出失败: ${result.message}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.settings_backup_restore, color: theme.colorScheme.primary),
                    title: const Text('导入数据库'),
                    subtitle: const Text('从备份文件导入整个数据库'),
                    onTap: () async {
                      // 首先显示说明对话框
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('导入数据库说明'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('请选择备份的数据库文件：'),
                              SizedBox(height: 8),
                              Text('• 选择格式为 gtd_db_*.db 的数据库文件'),
                              Text('• 导入后将完全替换现有数据库'),
                              Text('• 此操作不可撤销'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('明白了'),
                            ),
                          ],
                        ),
                      );
                      
                      if (!context.mounted) return;
                      
                      // 显式等待一段时间，确保UI更新
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // 让用户选择数据库文件
                      try {
                        print('正在打开文件选择器...');
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                        );
                        print('文件选择结果: ${result != null ? '已选择文件' : '未选择文件'}');
                        
                        if (result == null) {
                          // 用户未选择文件
                          print('用户取消了文件选择');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('未选择数据库文件'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          return;
                        }
                        
                        if (!context.mounted) return;
                        
                        final filePath = result.files.single.path;
                        if (filePath == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('无法获取文件路径'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        // 继续导入流程
                        final shouldImport = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认导入'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('导入数据库将替换所有现有数据，此操作不可撤销。'),
                                const SizedBox(height: 8),
                                Text('选择的文件: ${filePath.split('/').last}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text('确定要继续吗？'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('确定导入'),
                              ),
                            ],
                          ),
                        );
                        
                        if (shouldImport != true || !context.mounted) return;
                        
                        // 调用实际导入功能
                        final result2 = await BackupHelper.importDatabase(context, filePath: filePath);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result2.success 
                                  ? '数据库导入成功: ${result2.message}'
                                  : '导入失败: ${result2.message}'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        print('文件选择或导入过程中出错: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('导入数据库失败: $e'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // App Introduction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '软件介绍',
                  style: sectionTitleStyle,
                ),
                
                const SizedBox(height: 10),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Developer Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '开发者信息',
                  style: sectionTitleStyle,
                ),
                
                const SizedBox(height: 10),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.email, color: theme.colorScheme.primary),
                        title: const Text('联系我们'),
                        subtitle: const Text('support@example.com'),
                      ),
                      const Divider(height: 1, indent: 70),
                      ListTile(
                        leading: Icon(Icons.web, color: theme.colorScheme.primary),
                        title: const Text('官方网站'),
                        subtitle: const Text('www.example.com'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }
} 