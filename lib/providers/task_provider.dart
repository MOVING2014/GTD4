import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../data/mock_data.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  
  TaskProvider() {
    // Load mock data initially
    _tasks = MockData.getDemoTasks();
  }
  
  // Get all tasks
  List<Task> get allTasks => List.unmodifiable(_tasks);
  
  // Get tasks by project id
  List<Task> getTasksByProject(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }
  
  // Get tasks due today
  List<Task> get tasksForToday {
    final now = DateTime.now();
    return _tasks
        .where((task) => 
          task.dueDate != null && 
          task.dueDate!.year == now.year && 
          task.dueDate!.month == now.month && 
          task.dueDate!.day == now.day)
        .toList();
  }
  
  // Get tasks due on a specific date
  List<Task> getTasksForDate(DateTime date) {
    return _tasks
        .where((task) => 
          task.dueDate != null && 
          task.dueDate!.year == date.year && 
          task.dueDate!.month == date.month && 
          task.dueDate!.day == date.day)
        .toList();
  }
  
  // Get overdue tasks
  List<Task> get overdueTasks {
    final now = DateTime.now();
    return _tasks
        .where((task) => 
          task.dueDate != null && 
          task.dueDate!.isBefore(DateTime(now.year, now.month, now.day)) &&
          task.status != TaskStatus.completed)
        .toList();
  }
  
  // Add a new task
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }
  
  // Update an existing task
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }
  
  // Delete a task
  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }
  
  // Toggle task completion status
  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newStatus = task.status == TaskStatus.completed 
          ? TaskStatus.notStarted 
          : TaskStatus.completed;
      
      _tasks[index] = task.copyWith(
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
      );
      
      notifyListeners();
    }
  }
} 