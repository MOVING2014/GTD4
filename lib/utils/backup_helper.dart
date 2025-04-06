import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/database_helper.dart';
import '../models/task.dart';
import '../models/project.dart';

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

  // Export data to CSV
  static Future<BackupResult> exportData(BuildContext context) async {
    try {
      // Request permissions first
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        return BackupResult(
          success: false,
          message: '无法获取必要的存储权限，请在系统设置中授予应用存储权限',
        );
      }
      
      // Get data from database
      final db = DatabaseHelper.instance;
      final tasks = await db.getAllTasks();
      final projects = await db.getAllProjects();

      // Convert tasks to CSV
      final tasksCsv = await _tasksToCSV(tasks);
      
      // Convert projects to CSV
      final projectsCsv = await _projectsToCSV(projects);

      // Get timestamp for filenames
      final now = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      
      // Get Download directory path
      String directoryPath;
      String pathDesc;
      
      if (Platform.isAndroid) {
        // 使用公共Download文件夹
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            try {
              // Test file writing permission by creating a temporary file
              final testFile = File('${downloadDir.path}/tmp_test_gtd.txt');
              await testFile.writeAsString('test');
              await testFile.delete(); // Clean up
              directoryPath = downloadDir.path;
              pathDesc = 'Download/TaskManager 文件夹';
            } catch (e) {
              // 无法写入公共Download目录，降级到应用专用目录
              print('Cannot write to Download directory: $e');
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
          print('Error accessing Download directory: $e');
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
      
      // Create TaskManager subdirectory in Download
      final appDir = Directory(path.join(directoryPath, 'TaskManager'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      
      // Save tasks CSV file
      final tasksPath = path.join(appDir.path, 'tasks_$now.csv');
      final tasksFile = File(tasksPath);
      await tasksFile.writeAsString(tasksCsv);
      
      // Save projects CSV file
      final projectsPath = path.join(appDir.path, 'projects_$now.csv');
      final projectsFile = File(projectsPath);
      await projectsFile.writeAsString(projectsCsv);

      return BackupResult(
        success: true,
        message: '已导出 ${tasks.length} 个任务和 ${projects.length} 个项目到：\n$pathDesc',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '导出失败: $e',
      );
    }
  }

  // Get suitable storage directory based on platform
  static Future<Directory?> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        // 尝试使用文档目录作为备选
        return await getApplicationDocumentsDirectory();
      } catch (e) {
        print('Error accessing documents directory: $e');
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
            print('Cannot write to macOS Downloads directory: $e');
            // 失败时回退到文档目录
            return await getApplicationDocumentsDirectory();
          }
        }
        return await getApplicationDocumentsDirectory();
      } catch (e) {
        print('Error accessing macOS directories: $e');
        return await getApplicationDocumentsDirectory();
      }
    } else {
      // For other platforms, use the app documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  // Import data from CSV
  static Future<BackupResult> importData(BuildContext context) async {
    try {
      // Request permissions first
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        return BackupResult(
          success: false,
          message: '无法获取必要的存储权限，请在系统设置中授予应用存储权限',
        );
      }
      
      List<Task>? tasks;
      List<Project>? projects;
      
      // Show instructions dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入数据说明'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('请选择CSV备份文件：'),
              SizedBox(height: 8),
              Text('• 先选择tasks开头的CSV文件'),
              Text('• 再选择projects开头的CSV文件'),
              Text('• 导入后将替换现有数据'),
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
      
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      // Let user pick tasks file
      FilePickerResult? tasksResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: '选择任务文件 (tasks_*.csv)',
      );
      
      if (tasksResult == null || tasksResult.files.isEmpty) {
        return BackupResult(success: false, message: '未选择任务文件');
      }
      
      String? selectedTaskFile = tasksResult.files.single.path;
      
      if (selectedTaskFile == null || !await File(selectedTaskFile).exists()) {
        return BackupResult(success: false, message: '任务文件无效');
      }
      
      // Let user pick projects file
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      FilePickerResult? projectsResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: '选择项目文件 (projects_*.csv)',
      );
      
      if (projectsResult == null || projectsResult.files.isEmpty) {
        return BackupResult(success: false, message: '未选择项目文件');
      }
      
      String? selectedProjectFile = projectsResult.files.single.path;
      
      if (selectedProjectFile == null || !await File(selectedProjectFile).exists()) {
        return BackupResult(success: false, message: '项目文件无效');
      }
      
      // Read the selected files
      try {
        final taskCsv = await File(selectedTaskFile).readAsString();
        tasks = await _csvToTasks(taskCsv);
        
        final projectCsv = await File(selectedProjectFile).readAsString();
        projects = await _csvToProjects(projectCsv);
      } catch (e) {
        return BackupResult(success: false, message: '读取CSV文件失败: $e');
      }
      
      // Confirm before import
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入'),
          content: Text('将导入 ${tasks?.length ?? 0} 个任务和 ${projects?.length ?? 0} 个项目，这将覆盖现有数据。确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定导入'),
            ),
          ],
        ),
      );
      
      if (shouldImport != true) {
        return BackupResult(success: false, message: '导入已取消');
      }
      
      // Import data to database
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在导入数据，请稍候...'),
            ],
          ),
        ),
      );
      
      // Perform import
      final db = DatabaseHelper.instance;
      
      // Clear existing data
      await db.clearAllData();
      
      // Import projects first
      for (var project in projects) {
        await db.insertProject(project);
      }
      
      // Then import tasks
      for (var task in tasks) {
        await db.insertTask(task);
      }
      
      // Close progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return BackupResult(
        success: true,
        message: '已导入 ${tasks.length} 个任务和 ${projects.length} 个项目',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '导入失败: $e',
      );
    }
  }

  // Convert tasks to CSV
  static Future<String> _tasksToCSV(List<Task> tasks) async {
    final List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add([
      'id', 'title', 'notes', 'dueDate', 'reminderDate', 'priority', 
      'status', 'createdAt', 'completedAt', 'projectId', 'tags', 
      'isRecurring', 'recurrenceRule'
    ]);
    
    // Add data rows
    for (var task in tasks) {
      rows.add([
        task.id,
        task.title,
        task.notes ?? '',
        task.dueDate?.toIso8601String() ?? '',
        task.reminderDate?.toIso8601String() ?? '',
        task.priority.index,
        task.status.index,
        task.createdAt.toIso8601String(),
        task.completedAt?.toIso8601String() ?? '',
        task.projectId ?? '',
        jsonEncode(task.tags),
        task.isRecurring ? 1 : 0,
        task.recurrenceRule ?? '',
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }

  // Convert projects to CSV
  static Future<String> _projectsToCSV(List<Project> projects) async {
    final List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add([
      'id', 'name', 'description', 'colorValue', 'status', 
      'createdAt', 'completedAt', 'parentProjectId', 'order', 
      'needsMonthlyReview', 'lastReviewDate'
    ]);
    
    // Add data rows
    for (var project in projects) {
      rows.add([
        project.id,
        project.name,
        project.description ?? '',
        project.color.value,
        project.status.index,
        project.createdAt.toIso8601String(),
        project.completedAt?.toIso8601String() ?? '',
        project.parentProjectId ?? '',
        project.order ?? 0,
        project.needsMonthlyReview ? 1 : 0,
        project.lastReviewDate?.toIso8601String() ?? '',
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }

  // Convert CSV to tasks
  static Future<List<Task>> _csvToTasks(String csv) async {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csv);
    final List<Task> tasks = [];
    
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.length < 13) continue;
      
      tasks.add(Task(
        id: row[0].toString(),
        title: row[1].toString(),
        notes: row[2].toString().isNotEmpty ? row[2].toString() : null,
        dueDate: row[3].toString().isNotEmpty ? DateTime.parse(row[3].toString()) : null,
        reminderDate: row[4].toString().isNotEmpty ? DateTime.parse(row[4].toString()) : null,
        priority: TaskPriority.values[int.parse(row[5].toString())],
        status: TaskStatus.values[int.parse(row[6].toString())],
        createdAt: DateTime.parse(row[7].toString()),
        completedAt: row[8].toString().isNotEmpty ? DateTime.parse(row[8].toString()) : null,
        projectId: row[9].toString().isNotEmpty ? row[9].toString() : null,
        tags: row[10].toString().isNotEmpty ? List<String>.from(jsonDecode(row[10].toString())) : [],
        isRecurring: row[11].toString() == '1',
        recurrenceRule: row[12].toString().isNotEmpty ? row[12].toString() : null,
      ));
    }
    
    return tasks;
  }

  // Convert CSV to projects
  static Future<List<Project>> _csvToProjects(String csv) async {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csv);
    final List<Project> projects = [];
    
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.length < 11) continue;
      
      projects.add(Project(
        id: row[0].toString(),
        name: row[1].toString(),
        description: row[2].toString().isNotEmpty ? row[2].toString() : null,
        color: Color(int.parse(row[3].toString())),
        status: ProjectStatus.values[int.parse(row[4].toString())],
        createdAt: DateTime.parse(row[5].toString()),
        completedAt: row[6].toString().isNotEmpty ? DateTime.parse(row[6].toString()) : null,
        parentProjectId: row[7].toString().isNotEmpty ? row[7].toString() : null,
        order: row[8].toString() != '0' ? int.parse(row[8].toString()) : null,
        needsMonthlyReview: row[9].toString() == '1',
        lastReviewDate: row[10].toString().isNotEmpty ? DateTime.parse(row[10].toString()) : null,
      ));
    }
    
    return projects;
  }

  // 合并任务和项目数据为单个CSV
  static Future<String> _mergeCsvData(List<Task> tasks, List<Project> projects) async {
    final List<List<dynamic>> rows = [];
    
    // 添加标题行
    rows.add([
      'type', 'title', 'description', 'dueDate', 'reminderDate', 'priority', 
      'status', 'createdAt', 'completedAt', 'projectName', 'tags', 
      'isRecurring', 'recurrenceRule', 'colorValue', 'parentProject',
      'order', 'needsMonthlyReview', 'lastReviewDate'
    ]);
    
    // 添加任务数据行
    final projectMap = {for (var p in projects) p.id: p.name};
    
    for (var task in tasks) {
      final projectName = task.projectId != null ? projectMap[task.projectId] ?? '' : '';
      
      rows.add([
        'task',
        task.title,
        task.notes ?? '',
        task.dueDate?.toIso8601String() ?? '',
        task.reminderDate?.toIso8601String() ?? '',
        task.priority.index,
        task.status.index,
        task.createdAt.toIso8601String(),
        task.completedAt?.toIso8601String() ?? '',
        projectName,
        jsonEncode(task.tags),
        task.isRecurring ? 1 : 0,
        task.recurrenceRule ?? '',
        '', // colorValue (空)
        '', // parentProject (空)
        '', // order (空)
        '', // needsMonthlyReview (空)
        '', // lastReviewDate (空)
      ]);
    }
    
    // 创建父项目映射
    final parentProjectMap = {for (var p in projects) p.id: p.name};
    
    // 添加项目数据行
    for (var project in projects) {
      final parentProjectName = project.parentProjectId != null ? 
          parentProjectMap[project.parentProjectId] ?? '' : '';
      
      rows.add([
        'project',
        project.name,
        project.description ?? '',
        '', // dueDate (空)
        '', // reminderDate (空)
        '', // priority (空)
        project.status.index,
        project.createdAt.toIso8601String(),
        project.completedAt?.toIso8601String() ?? '',
        '', // projectName (空)
        '', // tags (空)
        '', // isRecurring (空)
        '', // recurrenceRule (空)
        project.color.value,
        parentProjectName,
        project.order ?? 0,
        project.needsMonthlyReview ? 1 : 0,
        project.lastReviewDate?.toIso8601String() ?? '',
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }
  
  // 从合并的CSV中提取任务和项目
  static Future<Map<String, dynamic>> _extractFromMergedCsv(String csv) async {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csv);
    final List<Task> tasks = [];
    final List<Project> projects = [];
    final Map<String, String> projectIdByName = {};
    
    // 先处理项目行，创建项目ID映射
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.length < 18) continue;
      
      final type = row[0].toString().toLowerCase();
      if (type != 'project') continue;
      
      final projectName = row[1].toString();
      final projectId = _generateUUID();
      projectIdByName[projectName] = projectId;
      
      projects.add(Project(
        id: projectId,
        name: projectName,
        description: row[2].toString().isNotEmpty ? row[2].toString() : null,
        color: row[13].toString().isNotEmpty ? Color(int.parse(row[13].toString())) : Colors.blue,
        status: row[6].toString().isNotEmpty ? ProjectStatus.values[int.parse(row[6].toString())] : ProjectStatus.active,
        createdAt: row[7].toString().isNotEmpty ? DateTime.parse(row[7].toString()) : DateTime.now(),
        completedAt: row[8].toString().isNotEmpty ? DateTime.parse(row[8].toString()) : null,
        parentProjectId: null, // 先设为null，稍后处理
        order: row[15].toString().isNotEmpty ? int.parse(row[15].toString()) : null,
        needsMonthlyReview: row[16].toString() == '1',
        lastReviewDate: row[17].toString().isNotEmpty ? DateTime.parse(row[17].toString()) : null,
      ));
    }
    
    // 设置项目的父项目ID
    for (int i = 0; i < projects.length; i++) {
      final row = rows[i + 1]; // 加1跳过标题行
      if (row[0].toString().toLowerCase() != 'project') continue;
      
      final parentProjectName = row[14].toString();
      if (parentProjectName.isNotEmpty && projectIdByName.containsKey(parentProjectName)) {
        projects[i] = projects[i].copyWith(
          parentProjectId: projectIdByName[parentProjectName],
        );
      }
    }
    
    // 处理任务行
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.length < 18) continue;
      
      final type = row[0].toString().toLowerCase();
      if (type != 'task') continue;
      
      final projectName = row[9].toString();
      String? projectId;
      if (projectName.isNotEmpty && projectIdByName.containsKey(projectName)) {
        projectId = projectIdByName[projectName];
      }
      
      tasks.add(Task(
        id: _generateUUID(),
        title: row[1].toString(),
        notes: row[2].toString().isNotEmpty ? row[2].toString() : null,
        dueDate: row[3].toString().isNotEmpty ? DateTime.parse(row[3].toString()) : null,
        reminderDate: row[4].toString().isNotEmpty ? DateTime.parse(row[4].toString()) : null,
        priority: row[5].toString().isNotEmpty ? TaskPriority.values[int.parse(row[5].toString())] : TaskPriority.none,
        status: row[6].toString().isNotEmpty ? TaskStatus.values[int.parse(row[6].toString())] : TaskStatus.notStarted,
        createdAt: row[7].toString().isNotEmpty ? DateTime.parse(row[7].toString()) : DateTime.now(),
        completedAt: row[8].toString().isNotEmpty ? DateTime.parse(row[8].toString()) : null,
        projectId: projectId,
        tags: row[10].toString().isNotEmpty ? List<String>.from(jsonDecode(row[10].toString())) : [],
        isRecurring: row[11].toString() == '1',
        recurrenceRule: row[12].toString().isNotEmpty ? row[12].toString() : null,
      ));
    }
    
    return {
      'tasks': tasks,
      'projects': projects,
    };
  }
  
  // 生成UUID作为新ID
  static String _generateUUID() {
    final random = DateTime.now().millisecondsSinceEpoch.toString() + 
                   (1000 + (DateTime.now().microsecond % 9000)).toString();
    return random;
  }

  // 导出合并的CSV数据
  static Future<BackupResult> exportMergedData(BuildContext context) async {
    try {
      // 请求权限
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        return BackupResult(
          success: false,
          message: '无法获取必要的存储权限，请在系统设置中授予应用存储权限',
        );
      }
      
      // 从数据库获取数据
      final db = DatabaseHelper.instance;
      final tasks = await db.getAllTasks();
      final projects = await db.getAllProjects();

      // 转换为合并的CSV
      final mergedCsv = await _mergeCsvData(tasks, projects);

      // 获取时间戳
      final now = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      
      // 获取目录路径
      String directoryPath;
      String pathDesc;
      
      if (Platform.isAndroid) {
        try {
          // 尝试使用外部存储下载目录
          final directory = await _getDownloadDirectory();
          if (directory == null) {
            // 如果下载目录不可用，回退到应用目录
            final appDirectory = await _getStorageDirectory();
            if (appDirectory == null) {
              return BackupResult(
                success: false,
                message: '无法访问存储目录',
              );
            }
            directoryPath = appDirectory.path;
            pathDesc = '应用内存储';
          } else {
            directoryPath = directory.path;
            pathDesc = '设备下载文件夹';
          }
        } catch (e) {
          // 获取公共Download目录时出错，降级到应用专用目录
          final directory = await getExternalStorageDirectory();
          if (directory == null) {
            return BackupResult(
              success: false,
              message: '无法访问存储目录',
            );
          }
          directoryPath = directory.path;
          pathDesc = '应用专用存储空间';
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
        pathDesc = '应用专用存储空间';
      }
      
      // 创建TaskManager子目录
      final appDir = Directory(path.join(directoryPath, 'TaskManager'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      
      // 保存CSV文件
      final mergedFilePath = path.join(appDir.path, 'gtd_merged_$now.csv');
      await File(mergedFilePath).writeAsString(mergedCsv);
      
      return BackupResult(
        success: true,
        message: '已导出数据到 $pathDesc 的TaskManager文件夹\n文件名: gtd_merged_$now.csv',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '导出失败: $e',
      );
    }
  }
  
  // 导入合并的CSV数据
  static Future<BackupResult> importMergedData(BuildContext context) async {
    try {
      // 请求权限
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        return BackupResult(
          success: false,
          message: '无法获取必要的存储权限，请在系统设置中授予应用存储权限',
        );
      }
      
      // 显示说明对话框
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入合并数据说明'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('请选择合并格式的CSV备份文件：'),
              SizedBox(height: 8),
              Text('• 选择以gtd_merged_开头的CSV文件'),
              Text('• 导入后将根据标题自动去重'),
              Text('• 所有任务和项目将获得新的ID'),
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
      
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      // 让用户选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: '选择合并CSV文件',
      );
      
      if (result == null || result.files.isEmpty) {
        return BackupResult(success: false, message: '未选择文件');
      }
      
      String? selectedFile = result.files.single.path;
      
      if (selectedFile == null || !await File(selectedFile).exists()) {
        return BackupResult(success: false, message: '文件无效');
      }
      
      // 读取选择的文件
      String csvContent;
      try {
        csvContent = await File(selectedFile).readAsString();
      } catch (e) {
        return BackupResult(success: false, message: '读取CSV文件失败: $e');
      }
      
      // 解析CSV数据
      Map<String, dynamic> data;
      try {
        data = await _extractFromMergedCsv(csvContent);
      } catch (e) {
        return BackupResult(success: false, message: '解析CSV文件失败: $e');
      }
      
      final tasks = data['tasks'] as List<Task>;
      final projects = data['projects'] as List<Project>;
      
      // 确认导入
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入'),
          content: Text('将导入 ${tasks.length} 个任务和 ${projects.length} 个项目，这将覆盖现有数据。确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定导入'),
            ),
          ],
        ),
      );
      
      if (shouldImport != true) {
        return BackupResult(success: false, message: '导入已取消');
      }
      
      // 导入数据到数据库
      if (!context.mounted) return BackupResult(success: false, message: '操作已取消');
      
      // 显示进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在导入数据，请稍候...'),
            ],
          ),
        ),
      );
      
      // 执行导入
      final db = DatabaseHelper.instance;
      
      // 清除现有数据
      await db.clearAllData();
      
      // 先导入项目
      for (var project in projects) {
        await db.insertProject(project);
      }
      
      // 再导入任务
      for (var task in tasks) {
        await db.insertTask(task);
      }
      
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return BackupResult(
        success: true,
        message: '已导入 ${tasks.length} 个任务和 ${projects.length} 个项目',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '导入失败: $e',
      );
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
              print('Cannot write to Download directory: $e');
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
          print('Error accessing Download directory: $e');
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
        print('未提供文件路径，尝试使用文件选择器');
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
          print('文件选择失败: $e');
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
        print('已备份原数据库到: $tempBackupPath');
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
        
        print('正在复制数据库文件...');
        print('源路径: ${selectedFile.path}');
        print('目标路径: $dbPath');
        
        // 对于macOS，使用不同的复制方式
        if (Platform.isMacOS) {
          try {
            final bytes = await selectedFile.readAsBytes();
            await dbFile.writeAsBytes(bytes);
            print('使用readAsBytes/writeAsBytes复制成功');
          } catch (e) {
            print('readAsBytes/writeAsBytes复制失败: $e，尝试其他方法');
            
            // 尝试备用方式
            try {
              // 读取并写入
              final content = await selectedFile.readAsString();
              await dbFile.writeAsString(content);
              print('使用readAsString/writeAsString复制成功');
            } catch (e2) {
              print('所有复制方法失败: $e2');
              throw Exception('无法复制数据库文件: $e2');
            }
          }
        } else {
          // 非macOS平台使用标准复制
          await selectedFile.copy(dbPath);
        }
        
        print('数据库文件复制成功');
        
        // 重新打开数据库
        await db.database;
        print('数据库重新打开成功');
        
        // 删除临时备份
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.delete();
          print('临时备份已删除');
        }
      } catch (e) {
        // 如果导入失败，恢复原数据库
        print('导入失败，恢复备份: $e');
        final tempBackupFile = File(tempBackupPath);
        if (await tempBackupFile.exists()) {
          await tempBackupFile.copy(dbPath);
          await tempBackupFile.delete();
          print('原数据库已恢复');
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
      print('导入数据库过程中出现异常: $e');
      return BackupResult(
        success: false,
        message: '导入数据库失败: $e',
      );
    }
  }

  // 获取Download目录（仅Android可用）
  static Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        // 尝试使用外部存储下载目录
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) return null;
        
        // 通常外部存储路径为 /storage/emulated/0/Android/data/package/files
        // 需要回退到 /storage/emulated/0 再加上 Download
        final downloadsPath = '${externalDir.path.split('/Android')[0]}/Download';
        final downloadsDir = Directory(downloadsPath);
        
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }
        return null;
      } catch (e) {
        print('获取下载目录失败: $e');
        return null;
      }
    }
    // 非Android平台不支持
    return null;
  }
} 