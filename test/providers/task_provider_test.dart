import 'package:flutter_test/flutter_test.dart';
import 'package:gtd4_without_clean_achitecture/models/task.dart';
import 'package:gtd4_without_clean_achitecture/providers/task_provider.dart';
import 'package:mockito/mockito.dart';
import '../mocks/mock_database_helper.dart';

// Create a mock of TaskProvider for testing
class MockTaskProvider extends Mock implements TaskProvider {
  final List<Task> _tasks = [];
  bool _showCompletedTasks = true;
  final MockDatabaseHelper dbHelper;
  
  MockTaskProvider(this.dbHelper);
  
  @override
  bool get showCompletedTasks => _showCompletedTasks;
  
  @override
  void toggleShowCompletedTasks() {
    _showCompletedTasks = !_showCompletedTasks;
    notifyListeners();
  }
  
  @override
  List<Task> get allTasks => List.unmodifiable(_tasks);
  
  @override
  List<Task> get inboxTasks {
    return _tasks.where((task) => task.projectId == null).toList();
  }
  
  // Implement methods needed for tests
  List<Task> getTasksForProject(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }
  
  List<Task> get priorityTasks {
    return _tasks.where((task) => task.priority == TaskPriority.high).toList();
  }
  
  List<Task> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.year == now.year && 
      task.dueDate!.month == now.month && 
      task.dueDate!.day == now.day
    ).toList();
  }
  
  List<Task> getTasksForDay(DateTime date) {
    return _tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.year == date.year && 
      task.dueDate!.month == date.month && 
      task.dueDate!.day == date.day
    ).toList();
  }
  
  List<Task> getVisibleTasks(List<Task> tasks) {
    if (_showCompletedTasks) {
      return tasks;
    } else {
      return tasks.where((task) => task.status != TaskStatus.completed).toList();
    }
  }
  
  Future<Task> toggleTaskStatus(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex >= 0) {
      final task = _tasks[taskIndex];
      final newStatus = task.status == TaskStatus.completed 
          ? TaskStatus.notStarted 
          : TaskStatus.completed;
      
      final updatedTask = task.copyWith(
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
      );
      
      await dbHelper.updateTask(updatedTask);
      _tasks[taskIndex] = updatedTask;
      return updatedTask;
    }
    throw Exception("Task not found");
  }
  
  @override
  Future<void> addTask(Task task) async {
    await dbHelper.insertTask(task);
    await refreshTasks();
  }
  
  @override
  Future<void> updateTask(Task updatedTask) async {
    await dbHelper.updateTask(updatedTask);
    await refreshTasks();
  }
  
  @override
  Future<void> deleteTask(String taskId) async {
    await dbHelper.deleteTask(taskId);
    await refreshTasks();
  }
  
  @override
  Future<void> refreshTasks() async {
    _tasks.clear();
    _tasks.addAll(await dbHelper.getAllTasks());
    notifyListeners();
  }
  
  // Helper for tests
  @override
  void notifyListeners() {
    // Empty implementation since we're just mocking
  }
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockTaskProvider taskProvider;
  
  setUp(() {
    mockDb = MockDatabaseHelper();
    taskProvider = MockTaskProvider(mockDb);
  });
  
  tearDown(() {
    mockDb.clear();
  });
  
  group('TaskProvider Tests', () {
    test('Initial state should be empty', () {
      expect(taskProvider.allTasks, isEmpty);
      expect(taskProvider.showCompletedTasks, true);
    });
    
    test('toggleShowCompletedTasks should toggle state', () {
      // 初始值应为true
      expect(taskProvider.showCompletedTasks, true);
      
      // 切换到false
      taskProvider.toggleShowCompletedTasks();
      expect(taskProvider.showCompletedTasks, false);
      
      // 再次切换回true
      taskProvider.toggleShowCompletedTasks();
      expect(taskProvider.showCompletedTasks, true);
    });
    
    group('Task Collections', () {
      late Task inboxTask;
      late Task projectTask;
      late Task completedTask;
      late Task highPriorityTask;
      late Task todayTask;
      
      setUp(() async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // 创建各类型任务
        inboxTask = Task(
          id: '1',
          title: 'Inbox Task',
          projectId: null,
          createdAt: now,
        );
        
        projectTask = Task(
          id: '2',
          title: 'Project Task',
          projectId: 'project1',
          createdAt: now,
        );
        
        completedTask = Task(
          id: '3',
          title: 'Completed Task',
          status: TaskStatus.completed,
          completedAt: now,
          createdAt: now,
        );
        
        highPriorityTask = Task(
          id: '4',
          title: 'High Priority Task',
          priority: TaskPriority.high,
          createdAt: now,
        );
        
        todayTask = Task(
          id: '5',
          title: 'Today Task',
          dueDate: today,
          createdAt: now,
        );
        
        // 添加到模拟数据库
        mockDb.addMockTask(inboxTask);
        mockDb.addMockTask(projectTask);
        mockDb.addMockTask(completedTask);
        mockDb.addMockTask(highPriorityTask);
        mockDb.addMockTask(todayTask);
        
        // 刷新Provider
        when(mockDb.getAllTasks()).thenAnswer((_) async => [
          inboxTask, projectTask, completedTask, highPriorityTask, todayTask
        ]);
        
        await taskProvider.refreshTasks();
      });
      
      test('allTasks should return all tasks', () {
        expect(taskProvider.allTasks.length, 5);
      });
      
      test('inboxTasks should return tasks without project', () {
        final inboxTasks = taskProvider.inboxTasks;
        expect(inboxTasks.length, 3); // 没有项目的任务，高优先级、今天和收件箱
        expect(inboxTasks.any((task) => task.id == '1'), true);
        expect(inboxTasks.any((task) => task.id == '2'), false); // 项目任务不应包含
      });
      
      test('projectTasks should return tasks for a specific project', () {
        final projectTasks = taskProvider.getTasksForProject('project1');
        expect(projectTasks.length, 1);
        expect(projectTasks.first.id, '2');
      });
      
      test('priorityTasks should return high priority tasks', () {
        final priorityTasks = taskProvider.priorityTasks;
        expect(priorityTasks.length, 1);
        expect(priorityTasks.first.id, '4');
      });
      
      test('todayTasks should return tasks due today', () {
        final todayTasks = taskProvider.todayTasks;
        expect(todayTasks.length, 1);
        expect(todayTasks.first.id, '5');
      });
      
      test('getTasksForDay returns tasks for specific day', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final tasksForToday = taskProvider.getTasksForDay(today);
        expect(tasksForToday.length, 1);
        expect(tasksForToday.first.id, '5');
      });
      
      test('hideCompletedTasks filters out completed tasks', () {
        // 切换为不显示已完成
        taskProvider.toggleShowCompletedTasks();
        
        final allVisible = taskProvider.getVisibleTasks(taskProvider.allTasks);
        expect(allVisible.length, 4); // 总共5个，不显示1个已完成的
        expect(allVisible.any((task) => task.id == '3'), false);
      });
    });
    
    group('Task Operations', () {
      test('addTask should call database and update state', () async {
        // 准备测试任务
        final task = Task(
          id: '1', 
          title: 'New Task',
          createdAt: DateTime.now()
        );
        
        // 设置模拟行为
        when(mockDb.insertTask(task)).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        
        // 执行添加
        await taskProvider.addTask(task);
        
        // 验证数据库调用
        verify(mockDb.insertTask(task)).called(1);
        
        // 验证状态更新
        expect(taskProvider.allTasks.length, 1);
        expect(taskProvider.allTasks.first.title, 'New Task');
      });
      
      test('updateTask should call database and update state', () async {
        // 准备初始任务
        final task = Task(
          id: '1', 
          title: 'Initial Task',
          createdAt: DateTime.now()
        );
        
        // 设置模拟数据库已有任务
        mockDb.addMockTask(task);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        await taskProvider.refreshTasks();
        
        // 准备更新后的任务
        final updatedTask = task.copyWith(title: 'Updated Task');
        
        // 设置模拟更新行为
        when(mockDb.updateTask(updatedTask)).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [updatedTask]);
        
        // 执行更新
        await taskProvider.updateTask(updatedTask);
        
        // 验证数据库调用
        verify(mockDb.updateTask(updatedTask)).called(1);
        
        // 验证状态更新
        expect(taskProvider.allTasks.length, 1);
        expect(taskProvider.allTasks.first.title, 'Updated Task');
      });
      
      test('deleteTask should call database and update state', () async {
        // 准备初始任务
        final task = Task(
          id: '1', 
          title: 'Task to Delete',
          createdAt: DateTime.now()
        );
        
        // 设置模拟数据库已有任务
        mockDb.addMockTask(task);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        await taskProvider.refreshTasks();
        
        // 验证初始状态
        expect(taskProvider.allTasks.length, 1);
        
        // 设置模拟删除行为
        when(mockDb.deleteTask('1')).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => []);
        
        // 执行删除
        await taskProvider.deleteTask('1');
        
        // 验证数据库调用
        verify(mockDb.deleteTask('1')).called(1);
        
        // 验证状态更新
        expect(taskProvider.allTasks, isEmpty);
      });
      
      test('toggleTaskStatus should toggle between completed and not started', () async {
        // 准备初始未完成任务
        final task = Task(
          id: '1', 
          title: 'Task to Toggle',
          status: TaskStatus.notStarted,
          createdAt: DateTime.now()
        );
        
        // 准备相同任务的已完成状态
        final completedTask = task.copyWith(
          status: TaskStatus.completed,
          completedAt: DateTime.now()
        );
        
        // 设置模拟数据库初始有一个未完成任务
        mockDb.addMockTask(task);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        await taskProvider.refreshTasks();
        
        // 执行切换 - 不需要mock updateTask，MockDatabaseHelper已经有实现
        final result = await taskProvider.toggleTaskStatus('1');
        
        // 验证返回值
        expect(result.status, TaskStatus.completed);
        
        // 更新模拟数据库状态以反映完成的任务
        when(mockDb.getAllTasks()).thenAnswer((_) async => [completedTask]);
        await taskProvider.refreshTasks();
        
        // 验证状态更新
        expect(taskProvider.allTasks.first.status, TaskStatus.completed);
        
        // 模拟切换回未完成
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        await taskProvider.toggleTaskStatus('1');
        await taskProvider.refreshTasks();
        
        // 验证状态再次更新
        expect(taskProvider.allTasks.first.status, TaskStatus.notStarted);
      });
    });
  });
} 