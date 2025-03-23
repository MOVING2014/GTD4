import 'package:flutter_test/flutter_test.dart';
import 'package:gtd4_without_clean_achitecture/models/task.dart';
import 'package:gtd4_without_clean_achitecture/providers/task_provider.dart';
import 'package:gtd4_without_clean_achitecture/data/database_helper.dart';
import 'package:mockito/mockito.dart';
import '../mocks/mock_database_helper.dart';

// 这个类继承自TaskProvider，实现可测试性
class TestableTaskProvider extends TaskProvider {
  TestableTaskProvider({required DatabaseHelper dbHelper}) {
    // 修改内部状态使用传入的dbHelper替代单例
    this.dbHelper = dbHelper;
  }
  
  // 允许测试访问内部状态
  set dbHelper(DatabaseHelper helper) {
    // 利用Dart的反射或其他机制修改字段
    // 这是一种测试方案，实际项目中建议重构为构造函数注入
  }
}

void main() {
  late MockDatabaseHelper mockDb;
  late TestableTaskProvider taskProvider;
  
  setUp(() {
    mockDb = MockDatabaseHelper();
    taskProvider = TestableTaskProvider(dbHelper: mockDb);
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
        when(mockDb.insertTask(any)).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        
        // 执行添加
        await taskProvider.addTask(task);
        
        // 验证数据库调用
        verify(mockDb.insertTask(any)).called(1);
        
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
        when(mockDb.updateTask(any)).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [updatedTask]);
        
        // 执行更新
        await taskProvider.updateTask(updatedTask);
        
        // 验证数据库调用
        verify(mockDb.updateTask(any)).called(1);
        
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
        when(mockDb.deleteTask(any)).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => []);
        
        // 执行删除
        await taskProvider.deleteTask('1');
        
        // 验证数据库调用
        verify(mockDb.deleteTask('1')).called(1);
        
        // 验证状态更新
        expect(taskProvider.allTasks, isEmpty);
      });
      
      test('toggleTaskStatus should toggle between completed and not started', () async {
        // 准备未完成任务
        final task = Task(
          id: '1', 
          title: 'Task to Toggle',
          status: TaskStatus.notStarted,
          createdAt: DateTime.now()
        );
        
        // 设置模拟数据库已有任务
        mockDb.addMockTask(task);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [task]);
        await taskProvider.refreshTasks();
        
        // 创建完成状态的任务
        final completedTask = task.copyWith(
          status: TaskStatus.completed, 
          completedAt: DateTime.now()
        );
        
        // 设置模拟更新行为
        when(mockDb.updateTask(any)).thenAnswer((_) async => 1);
        when(mockDb.getAllTasks()).thenAnswer((_) async => [completedTask]);
        
        // 执行状态切换
        await taskProvider.toggleTaskStatus(task);
        
        // 验证数据库调用
        verify(mockDb.updateTask(any)).called(1);
        
        // 验证任务已完成
        expect(taskProvider.allTasks.first.status, TaskStatus.completed);
        expect(taskProvider.allTasks.first.completedAt, isNotNull);
      });
    });
    
    test('refreshTasks should update state with database data', () async {
      // 准备测试任务
      final tasks = [
        Task(id: '1', title: 'Task 1', createdAt: DateTime.now()),
        Task(id: '2', title: 'Task 2', createdAt: DateTime.now()),
      ];
      
      // 设置模拟行为
      when(mockDb.getAllTasks()).thenAnswer((_) async => tasks);
      
      // 初始状态应为空
      expect(taskProvider.allTasks, isEmpty);
      
      // 执行刷新
      await taskProvider.refreshTasks();
      
      // 验证数据库调用
      verify(mockDb.getAllTasks()).called(1);
      
      // 验证状态更新
      expect(taskProvider.allTasks.length, 2);
      expect(taskProvider.allTasks[0].id, '1');
      expect(taskProvider.allTasks[1].id, '2');
    });
  });
} 