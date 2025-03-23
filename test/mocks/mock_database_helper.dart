import 'package:mockito/mockito.dart';
import 'package:gtd4_without_clean_achitecture/data/database_helper.dart';
import 'package:gtd4_without_clean_achitecture/models/task.dart';
import 'package:gtd4_without_clean_achitecture/models/project.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {
  final List<Task> _tasks = [];
  final List<Project> _projects = [];
  
  @override
  Future<List<Task>> getAllTasks() async {
    return _tasks;
  }
  
  @override
  Future<int> insertTask(Task task) async {
    _tasks.add(task);
    return 1; // 假设插入成功
  }
  
  @override
  Future<int> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
      return 1; // 假设更新成功
    }
    return 0; // 找不到要更新的任务
  }
  
  @override
  Future<int> deleteTask(String id) async {
    final initialLength = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    return initialLength - _tasks.length; // 返回删除的记录数
  }
  
  @override
  Future<List<Project>> getAllProjects() async {
    return _projects;
  }
  
  // 添加测试用任务
  void addMockTask(Task task) {
    _tasks.add(task);
  }
  
  // 添加测试用项目
  void addMockProject(Project project) {
    _projects.add(project);
  }
  
  // 清除所有测试数据
  void clear() {
    _tasks.clear();
    _projects.clear();
  }
} 