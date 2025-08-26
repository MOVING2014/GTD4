import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/database_helper.dart';
import 'logger.dart';

class BackupResult {
  final bool success;
  final String message;

  BackupResult({required this.success, required this.message});
}

class BackupHelper {
  // Request storage permissions
  static Future<bool> _requestPermissions() async {
    // 检查并请求权限
    if (Platform.isAndroid) {
      // 对于Android 10+，首先尝试使用管理外部存储权限
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      
      // 对于Android 10以下版本，使用标准存储权限
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      
      // 对于Android 13+，尝试使用媒体库权限
      if (await Permission.mediaLibrary.request().isGranted) {
        return true;
      }
      
      return false;
    }
    
    // iOS默认已有对应权限控制
    return true;
  }

  // Get suitable storage directory based on platform
  static Future<Directory?> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        // 尝试使用文档目录作为备选
        return await getApplicationDocumentsDirectory();
      } catch (e) {
        Logger.log('Error accessing documents directory: $e');
        return null;
      }
    } else if (Platform.isIOS) {
      // On iOS we use the Documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      // 在macOS上，使用Downloads目录
      try {
        final homeDir = await getApplicationDocumentsDirectory();
        // macOS的Downloads文件夹通常在用户主目录下
        final downloadDir = Directory('${homeDir.path}/../Downloads');
        if (await downloadDir.exists()) {
          try {
            // 测试权限
            final testPath = '${downloadDir.path}/gtd_tmp_test.txt';
            final testFile = File(testPath);
            await testFile.writeAsString('test');
            await testFile.delete();
            return downloadDir;
          } catch (e) {
            Logger.log('Cannot write to macOS Downloads directory: $e');
            // 失败时回退到文档目录
            return await getApplicationDocumentsDirectory();
          }
        }
        return await getApplicationDocumentsDirectory();
      } catch (e) {
        Logger.log('Error accessing macOS directories: $e');
        return await getApplicationDocumentsDirectory();
      }
    } else {
      // For other platforms, use the app documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  // 导出整个数据库
  static Future<BackupResult> exportDatabase(BuildContext context) async {
    try {
      // 请求权限
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        return BackupResult(
          success: false,
          message: '无法获取必要的存储权限，请在系统设置中授予应用存储权限',
        );
      }
      
      // 获取数据库文件路径
      final db = DatabaseHelper.instance;
      final dbPath = await db.getDatabasePath();
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        return BackupResult(
          success: false,
          message: '数据库文件不存在',
        );
      }
      
      // 获取时间戳用于文件名
      final now = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      
      // 获取Download目录路径
      String directoryPath;
      String pathDesc;
      
      if (Platform.isAndroid) {
        // 使用公共Download文件夹
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            try {
              // 测试写入权限
              final testFile = File('${downloadDir.path}/tmp_test_gtd.txt');
              await testFile.writeAsString('test');
              await testFile.delete(); // 清理
              directoryPath = downloadDir.path;
              pathDesc = 'Download/TaskManager 文件夹';
            } catch (e) {
              // 无法写入公共Download目录，降级到应用专用目录
              Logger.log('Cannot write to Download directory: $e');
              final directory = await getExternalStorageDirectory();
              if (directory == null) {
                return BackupResult(
                  success: false,
                  message: '无法访问存储目录',
                );
              }
              directoryPath = directory.path;
              pathDesc = '应用专用存储空间/TaskManager 文件夹';
            }
          } else {
            // 公共Download目录不存在，降级到应用专用目录
            final directory = await getExternalStorageDirectory();
            if (directory == null) {
              return BackupResult(
                success: false,
                message: '无法访问存储目录',
              );
            }
            directoryPath = directory.path;
            pathDesc = '应用专用存储空间/TaskManager 文件夹';
          }
        } catch (e) {
          // 获取公共Download目录时出错，降级到应用专用目录
          Logger.log('Error accessing Download directory: $e');
          final directory = await getExternalStorageDirectory();
          if (directory == null) {
            return BackupResult(
              success: false,
              message: '无法访问存储目录',
            );
          }
          directoryPath = directory.path;
          pathDesc = '应用专用存储空间/TaskManager 文件夹';
        }
      } else {
        // 其他平台使用应用专用存储
        final directory = await _getStorageDirectory();
        if (directory == null) {
          return BackupResult(
            success: false,
            message: '无法访问存储目录',
          );
        }
        directoryPath = directory.path;
        pathDesc = '应用专用存储空间/TaskManager 文件夹';
      }
      
      // 创建TaskManager子目录
      final appDir = Directory(path.join(directoryPath, 'TaskManager'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      
      // 复制数据库文件
      final dbBackupPath = path.join(appDir.path, 'gtd_db_$now.db');
      await dbFile.copy(dbBackupPath);
      
      return BackupResult(
        success: true,
        message: '已导出数据库到：\n$pathDesc',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '导出数据库失败: $e',
      );
    }
  }
  
  // 导入整个数据库
  static Future<BackupResult> importDatabase(BuildContext context, {String? filePath}) async {
    try {
      // 请求权限
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        return BackupResult(
          success: false,
          message: '无法获取必要的存储权限，请在系统设置中授予应用存储权限',
        );
      }
      
      // 在settings_screen.dart中已经处理了文件选择和确认对话框
      // 这里只处理实际的导入逻辑
      
      String? selectedFilePath = filePath;
      
      // 如果没有提供文件路径，则尝试使用文件选择器
      if (selectedFilePath == null) {
        Logger.log('未提供文件路径，尝试使用文件选择器');
        try {
          // 为macOS提供更多选项
          FilePickerResult? result;
          if (Platform.isMacOS) {
            result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['db'],
              allowMultiple: false,
              dialogTitle: '选择数据库文件',
              // macOS特定选项
              lockParentWindow: true,
            );
          } else {
            result = await FilePicker.platform.pickFiles(
              type: FileType.any,
            );
          }
          
          if (result == null || result.files.isEmpty) {
            return BackupResult(success: false, message: '未选择数据库文件');
          }
          
          selectedFilePath = result.files.single.path;
          
          if (selectedFilePath == null) {
            return BackupResult(success: false, message: '获取文件路径失败');
          }
        } catch (e) {
          Logger.log('文件选择失败: $e');
          return BackupResult(success: false, message: '文件选择失败: $e');
        }
      }
      
      // 显示进度对话框
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入数据库，请稍候...'),
              ],
            ),
          ),
        );
      }
      
      // 获取当前数据库路径和文件
      final db = DatabaseHelper.instance;
      await db.close(); // 关闭数据库连接
      
      final dbPath = await db.getDatabasePath();
      final dbFile = File(dbPath);
      
      // 备份现有数据库
      final tempBackupPath = '${dbPath}_temp_backup';
      if (await dbFile.exists()) {
        await dbFile.copy(tempBackupPath);
        Logger.log('已备份原数据库到: $tempBackupPath');
      }
      
      try {
        // 复制新数据库到应用目录
        final selectedFile = File(selectedFilePath);
        if (!await selectedFile.exists()) {
          // 如果选择的文件不存在，关闭进度对话框
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          return BackupResult(success: false, message: '选择的数据库文件不存在');
        }
        
        // 确保目标目录存在
        final dbDir = Directory(path.dirname(dbPath));
        if (!await dbDir.exists()) {
          await dbDir.create(recursive: true);
        }
        
        Logger.log('正在复制数据库文件...');
        Logger.log('源路径: ${selectedFile.path}');
        Logger.log('目标路径: $dbPath');
        
        // 对于macOS，使用不同的复制方式
        if (Platform.isMacOS) {
          try {
            final bytes = await selectedFile.readAsBytes();
            await dbFile.writeAsBytes(bytes);
            Logger.log('使用readAsBytes/writeAsBytes复制成功');
          } catch (e) {
            Logger.log('readAsBytes/writeAsBytes复制失败: $e，尝试其他方法');
            
            // 尝试备用方式
            try {
              // 读取并写入
              final content = await selectedFile.readAsString();
              await dbFile.writeAsString(content);
              Logger.log('使用readAsString/writeAsString复制成功');
            } catch (e2) {
              Logger.log('所有复制方法失败: $e2');
              throw Exception('无法复制数据库文件: $e2');
            }
          }
        } else {
          // 非macOS平台使用标准复制
          await selectedFile.copy(dbPath);
        }
        
        Logger.log('数据库文件复制成功');
        
        // 重新打开数据库
        await db.database;
        Logger.log('数据库重新打开成功');
        
        // 删除临时备份
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.delete();
          Logger.log('临时备份已删除');
        }
      } catch (e) {
        // 如果导入失败，恢复原数据库
        Logger.log('导入失败，恢复备份: $e');
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.copy(dbPath);
          await tempBackupFile.delete();
          Logger.log('原数据库已恢复');
        }
        
        // 关闭进度对话框
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        return BackupResult(
          success: false,
          message: '导入数据库失败: $e',
        );
      }
      
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      return BackupResult(
        success: true,
        message: '数据库导入成功，请重启应用以加载新数据',
      );
    } catch (e) {
      Logger.log('导入数据库过程中出现异常: $e');
      return BackupResult(
        success: false,
        message: '导入数据库失败: $e',
      );
    }
  }
}