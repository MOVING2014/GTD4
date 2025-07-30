import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/task.dart';
import '../data/database_helper.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  // 控制是否显示已完成的任务
  bool _showCompletedTasks = true;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  TaskProvider() {
    // 从数据库加载任务
    _loadTasks();
  }

  // 从数据库加载所有任务
  Future<void> _loadTasks() async {
    _tasks = await _dbHelper.getAllTasks();
    notifyListeners();
  }

  // 获取是否显示已完成任务的状态
  bool get showCompletedTasks => _showCompletedTasks;
  
  // 切换是否显示已完成任务
  void toggleShowCompletedTasks() {
    _showCompletedTasks = !_showCompletedTasks;
    notifyListeners();
  }
  
  // 根据当前的显示设置过滤任务
  List<Task> _filterTasks(List<Task> tasks) {
    if (_showCompletedTasks) {
      return tasks;
    } else {
      return tasks.where((task) => task.status != TaskStatus.completed).toList();
    }
  }
  
  // 辅助方法：按完成状态排序任务（未完成的在前，已完成的在后）
  List<Task> _sortTasksByCompletionStatus(List<Task> tasks) {
    // 创建一个副本以避免修改原列表
    final sortedTasks = List<Task>.from(tasks);
    // 排序：未完成的在前，已完成的在后
    sortedTasks.sort((a, b) {
      if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) {
        return 1; // a已完成，b未完成，a排在后面
      } else if (a.status != TaskStatus.completed && b.status == TaskStatus.completed) {
        return -1; // a未完成，b已完成，a排在前面
      } else {
        // 如果完成状态相同，则按到期日期排序（如果有）
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1; // a有到期日期，b没有，a排在前面
        } else if (b.dueDate != null) {
          return 1; // a没有到期日期，b有，a排在后面
        } else {
          return 0; // 两者都没有到期日期，保持原顺序
        }
      }
    });
    return sortedTasks;
  }
  
  // 处理任务列表：过滤+排序
  List<Task> _processTaskList(List<Task> tasks) {
    final filteredTasks = _filterTasks(tasks);
    return _sortTasksByCompletionStatus(filteredTasks);
  }
  
  // 获取收件箱任务（没有指定项目的任务）
  List<Task> get inboxTasks {
    final inboxTasks = _tasks.where((task) => task.projectId == null).toList();
    return _processTaskList(inboxTasks);
  }
  
  // 获取收件箱任务数量
  int get inboxTasksCount {
    return _tasks.where((task) => 
      task.projectId == null && 
      task.status != TaskStatus.completed
    ).length;
  }
  
  // 获取具有优先级的任务数量（橙色优先级，未完成的）
  int getPrioritizedTasksCount() {
    return _tasks.where((task) => 
      task.priority == TaskPriority.medium && 
      task.status != TaskStatus.completed
    ).length;
  }
  
  // Get all tasks
  List<Task> get allTasks {
    final tasks = List<Task>.from(_tasks);
    return List.unmodifiable(_processTaskList(tasks));
  }
  
  // Get tasks by project id
  List<Task> getTasksByProject(String projectId) {
    final projectTasks = _tasks.where((task) => task.projectId == projectId).toList();
    return _processTaskList(projectTasks);
  }
  
  // Get tasks due today
  List<Task> get tasksForToday {
    final now = DateTime.now();
    final todayTasks = _tasks
        .where((task) => 
          task.dueDate != null && 
          task.dueDate!.year == now.year && 
          task.dueDate!.month == now.month && 
          task.dueDate!.day == now.day)
        .toList();
    return _processTaskList(todayTasks);
  }
  
  // Get tasks due on a specific date
  List<Task> getTasksForDate(DateTime date) {
    final dateTasks = _tasks
        .where((task) => 
          task.dueDate != null && 
          task.dueDate!.year == date.year && 
          task.dueDate!.month == date.month && 
          task.dueDate!.day == date.day)
        .toList();
    return _processTaskList(dateTasks);
  }
  
  // Get overdue tasks
  List<Task> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final overdueTasks = _tasks
        .where((task) => 
          task.dueDate != null && 
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day).isBefore(today) &&
          task.status != TaskStatus.completed)
        .toList();
    return _processTaskList(overdueTasks);
  }
  
  // Add a new task
  Future<void> addTask(Task task) async {
    await _dbHelper.insertTask(task);
    await _loadTasks(); // 重新加载任务来更新UI
  }
  
  // Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    await _dbHelper.updateTask(updatedTask);
    await _loadTasks(); // 重新加载任务来更新UI
  }
  
  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _dbHelper.deleteTask(taskId);
    await _loadTasks(); // 重新加载任务来更新UI
  }
  
  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhereOrNull((task) => task.id == taskId);
    if (task == null) {
      // Task not found, return early
      return;
    }
    
    final newStatus = task.status == TaskStatus.completed 
        ? TaskStatus.notStarted 
        : TaskStatus.completed;
    
    final updatedTask = task.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );
    
    await _dbHelper.updateTask(updatedTask);
    await _loadTasks(); // 重新加载任务来更新UI
  }

  // 刷新任务列表
  Future<void> refreshTasks() async {
    await _loadTasks();
  }
} 