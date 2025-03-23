import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gtd4_without_clean_achitecture/models/task.dart';
import 'package:gtd4_without_clean_achitecture/widgets/task_list_item.dart';
import 'package:gtd4_without_clean_achitecture/providers/task_provider.dart';
import 'package:gtd4_without_clean_achitecture/providers/project_provider.dart';
import 'package:mockito/mockito.dart';
import '../mocks/mock_database_helper.dart';

// 创建模拟Provider类
class MockTaskProvider extends Mock implements TaskProvider {}
class MockProjectProvider extends Mock implements ProjectProvider {}

void main() {
  late MockTaskProvider mockTaskProvider;
  late MockProjectProvider mockProjectProvider;
  
  setUp(() {
    mockTaskProvider = MockTaskProvider();
    mockProjectProvider = MockProjectProvider();
  });
  
  Widget buildTestableWidget({required Task task, bool isDarkMode = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(
          value: mockTaskProvider,
        ),
        ChangeNotifierProvider<ProjectProvider>.value(
          value: mockProjectProvider,
        ),
      ],
      child: MaterialApp(
        theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: TaskListItem(
            task: task,
          ),
        ),
      ),
    );
  }
  
  group('TaskListItem Widget Tests', () {
    testWidgets('TaskListItem displays task title', (WidgetTester tester) async {
      // 创建测试任务
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: task));
      
      // 验证任务标题是否显示
      expect(find.text('Test Task'), findsOneWidget);
    });
    
    testWidgets('TaskListItem displays completed task with strikethrough', (WidgetTester tester) async {
      // 创建已完成的测试任务
      final completedTask = Task(
        id: '1',
        title: 'Completed Task',
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: completedTask));
      
      // 验证已完成任务有删除线样式
      final titleFinder = find.text('Completed Task');
      expect(titleFinder, findsOneWidget);
      
      // 查找文本小部件并验证样式
      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
    
    testWidgets('TaskListItem shows notes when expanded', (WidgetTester tester) async {
      // 创建带备注的任务
      final task = Task(
        id: '1',
        title: 'Task with Notes',
        notes: 'These are test notes',
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: task));
      
      // 初始时备注应该不可见
      expect(find.text('These are test notes'), findsNothing);
      
      // 点击展开按钮
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      
      // 展开后备注应该可见
      expect(find.text('These are test notes'), findsOneWidget);
    });
    
    testWidgets('TaskListItem shows priority indicator for high priority tasks', (WidgetTester tester) async {
      // 创建高优先级任务
      final highPriorityTask = Task(
        id: '1',
        title: 'High Priority Task',
        priority: TaskPriority.high,
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: highPriorityTask));
      
      // 验证优先级指示器存在 (可能是颜色、图标等)
      // 注意：具体的验证取决于优先级如何在UI中表示
      expect(find.byIcon(Icons.flag), findsOneWidget);
      
      // 如果使用颜色表示优先级，可以检查Container的颜色
    });
    
    testWidgets('TaskListItem shows due date for tasks with due date', (WidgetTester tester) async {
      // 创建带截止日期的任务
      final dueDate = DateTime(2023, 5, 15);
      final taskWithDueDate = Task(
        id: '1',
        title: 'Task with Due Date',
        dueDate: dueDate,
        createdAt: DateTime.now(),
      );
      
      // 设置ProjectProvider模拟行为
      when(mockProjectProvider.getProject(any)).thenReturn(null);
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: taskWithDueDate));
      
      // 日期格式可能会根据区域设置而变化，所以使用部分匹配
      expect(find.textContaining('5月15日'), findsOneWidget);
    });
    
    testWidgets('TaskListItem shows project name when task has project', (WidgetTester tester) async {
      // 创建带项目的任务
      final taskWithProject = Task(
        id: '1',
        title: 'Project Task',
        projectId: 'project1',
        createdAt: DateTime.now(),
      );
      
      // 设置ProjectProvider模拟行为，返回项目名称
      when(mockProjectProvider.getProject('project1')).thenReturn(
        Project(id: 'project1', name: 'Test Project', color: Colors.blue)
      );
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: taskWithProject));
      
      // 验证项目名称显示
      expect(find.textContaining('Test Project'), findsOneWidget);
    });
    
    testWidgets('TaskListItem checkbox toggles task status when tapped', (WidgetTester tester) async {
      // 创建未完成任务
      final incompleteTask = Task(
        id: '1',
        title: 'Incomplete Task',
        status: TaskStatus.notStarted,
        createdAt: DateTime.now(),
      );
      
      // 创建完成状态的同一个任务
      final completedTask = incompleteTask.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      
      // 设置TaskProvider模拟行为
      when(mockTaskProvider.toggleTaskStatus(any)).thenAnswer((_) async => completedTask);
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: incompleteTask));
      
      // 查找并点击复选框
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      
      // 验证Provider方法被调用
      verify(mockTaskProvider.toggleTaskStatus(any)).called(1);
    });
    
    testWidgets('TaskListItem adapts to dark mode', (WidgetTester tester) async {
      // 创建测试任务
      final task = Task(
        id: '1',
        title: 'Dark Mode Task',
        createdAt: DateTime.now(),
      );
      
      // 构建深色模式下的测试小部件
      await tester.pumpWidget(buildTestableWidget(task: task, isDarkMode: true));
      
      // 验证任务标题正确显示
      expect(find.text('Dark Mode Task'), findsOneWidget);
      
      // 在实际应用中，我们可以检查特定颜色是否适应了深色模式
      // 这需要深入查找特定小部件并检查它们的颜色属性
    });
    
    testWidgets('TaskListItem handles long task titles properly', (WidgetTester tester) async {
      // 创建带有非常长标题的任务
      final taskWithLongTitle = Task(
        id: '1',
        title: '这是一个非常长的任务标题，用于测试任务项组件如何处理长文本。它应该能够正确地显示和截断文本，而不会导致布局问题或溢出错误。',
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: taskWithLongTitle));
      
      // 验证没有溢出错误
      // 这通过检查是否有任何溢出错误的渲染对象间接完成
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('TaskListItem handles overdue tasks correctly', (WidgetTester tester) async {
      // 创建已逾期的任务（截止日期设为昨天）
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final overdueTask = Task(
        id: '1',
        title: 'Overdue Task',
        dueDate: yesterday,
        createdAt: DateTime.now(),
      );
      
      // 设置ProjectProvider模拟行为
      when(mockProjectProvider.getProject(any)).thenReturn(null);
      
      // 构建测试小部件
      await tester.pumpWidget(buildTestableWidget(task: overdueTask));
      
      // 验证任务标题显示
      expect(find.text('Overdue Task'), findsOneWidget);
      
      // 在实际应用中，我们可以检查特定颜色是否表示逾期状态
      // 这需要深入查找特定小部件并检查它们的颜色属性
    });
    
    // Golden测试示例 - 在真实的测试环境中需要存储黄金文件
    /* 
    testWidgets('TaskListItem matches golden file in light mode', (WidgetTester tester) async {
      // 创建标准测试任务
      final task = Task(
        id: '1',
        title: 'Golden Test Task',
        notes: 'Test notes for golden test',
        priority: TaskPriority.medium,
        dueDate: DateTime(2023, 5, 15),
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件并设置固定大小
      await tester.pumpWidget(
        Container(
          width: 400,
          child: buildTestableWidget(task: task),
        ),
      );
      
      // 比较与黄金文件
      await expectLater(
        find.byType(TaskListItem),
        matchesGoldenFile('goldens/task_list_item_light.png'),
      );
    });
    
    testWidgets('TaskListItem matches golden file in dark mode', (WidgetTester tester) async {
      // 创建标准测试任务
      final task = Task(
        id: '1',
        title: 'Golden Test Task',
        notes: 'Test notes for golden test',
        priority: TaskPriority.medium,
        dueDate: DateTime(2023, 5, 15),
        createdAt: DateTime.now(),
      );
      
      // 构建测试小部件并设置固定大小
      await tester.pumpWidget(
        Container(
          width: 400,
          child: buildTestableWidget(task: task, isDarkMode: true),
        ),
      );
      
      // 比较与黄金文件
      await expectLater(
        find.byType(TaskListItem),
        matchesGoldenFile('goldens/task_list_item_dark.png'),
      );
    });
    */
  });
} 