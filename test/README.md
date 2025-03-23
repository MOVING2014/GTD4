# Todo应用完整测试方案

本文档提供了GTD应用的全面测试策略，包括测试架构、具体实现方法和最佳实践。

## 1. 测试架构

### 1.1 测试类型

本项目采用金字塔测试策略，自下而上包括：

1. **单元测试**：
   - 模型测试：验证数据模型的属性和行为
   - 业务逻辑测试：验证Provider类的功能
   - 工具类测试：验证工具函数和扩展方法

2. **小部件测试**：
   - 独立组件测试：验证UI组件的渲染和交互
   - 状态管理测试：验证与Provider结合的UI状态更新

3. **集成测试**：
   - 页面导航测试：验证应用的导航逻辑
   - 功能流程测试：验证完整的用户操作流程
   - 黑盒测试：验证应用作为整体的功能

### 1.2 测试覆盖范围

| 模块        | 单元测试               | 小部件测试             | 集成测试              |
|------------|----------------------|----------------------|----------------------|
| 模型层      | ✅ 全覆盖              | -                    | -                    |
| Provider层 | ✅ 核心方法全覆盖        | ✅ 与UI交互测试         | -                    |
| UI组件层    | -                    | ✅ 主要组件全覆盖        | ✅ 屏幕交互全覆盖       |
| 页面层      | -                    | ✅ 页面渲染测试         | ✅ 页面间导航全覆盖     |
| 数据层      | ✅ CRUD操作全覆盖      | -                    | ✅ 数据持久化测试       |

### 1.3 目录结构

```
project_root/
├── test/
│   ├── models/              # 模型测试
│   │   ├── task_test.dart
│   │   ├── project_test.dart
│   │   └── tag_test.dart
│   ├── providers/           # Provider测试
│   │   ├── task_provider_test.dart
│   │   ├── project_provider_test.dart
│   │   └── filter_provider_test.dart
│   ├── widgets/             # 小部件测试
│   │   ├── task_list_item_test.dart
│   │   ├── project_item_test.dart
│   │   └── calendar_widget_test.dart
│   ├── screens/             # 屏幕测试
│   │   ├── calendar_screen_test.dart
│   │   ├── inbox_screen_test.dart
│   │   └── project_screen_test.dart
│   ├── utils/               # 工具类测试
│   │   ├── date_utils_test.dart
│   │   └── string_utils_test.dart
│   └── mocks/               # 模拟类
│       ├── mock_database_helper.dart
│       ├── mock_task_provider.dart
│       └── mock_navigator.dart
├── integration_test/        # 集成测试
│   ├── app_test.dart        # 应用整体测试
│   ├── task_flow_test.dart  # 任务管理流程测试
│   └── project_flow_test.dart # 项目管理流程测试
└── coverage/                # 测试覆盖率报告
```

## 2. 单元测试实现

### 2.1 模型测试策略

对每个模型类测试以下方面：
- 构造函数的正确性
- 属性的获取与设置
- 工厂方法（fromMap、toMap等）
- 业务逻辑方法
- 边界条件（例如空值、异常值）

#### Task模型测试示例：

```dart
group('Task Model Tests', () {
  // 基本实例化测试
  test('Task constructor creates valid instance', () {...});
  
  // 复制方法测试
  test('Task copyWith method creates a new instance with updated values', () {...});
  
  // 序列化测试
  test('Task can be serialized to and from Map', () {
    final task = Task(id: '1', title: 'Test', createdAt: DateTime.now());
    final map = task.toMap();
    final deserializedTask = Task.fromMap(map);
    expect(deserializedTask.id, task.id);
    expect(deserializedTask.title, task.title);
  });
  
  // 业务逻辑测试
  test('isOverdue returns correct value based on due date', () {...});
  
  // 边界条件测试
  test('Task with null values initializes with default values', () {
    final task = Task(id: '1', title: '', createdAt: DateTime.now());
    expect(task.notes, null);
    expect(task.dueDate, null);
    expect(task.isOverdue, false);
  });
});
```

### 2.2 Provider测试策略

对Provider类测试以下方面：
- 初始状态
- 公共方法的行为
- 数据加载与刷新
- 状态更新通知
- 错误处理

#### 使用依赖注入进行Provider测试：

```dart
class TestableTaskProvider extends TaskProvider {
  TestableTaskProvider({required DatabaseHelper dbHelper}) : super(dbHelper: dbHelper);
}

void main() {
  late MockDatabaseHelper mockDb;
  late TestableTaskProvider provider;
  
  setUp(() {
    mockDb = MockDatabaseHelper();
    provider = TestableTaskProvider(dbHelper: mockDb);
  });
  
  test('addTask should call database and update state', () async {
    // 准备测试任务
    final task = Task(id: '1', title: 'Test', createdAt: DateTime.now());
    
    // 设置模拟行为
    when(mockDb.insertTask(any)).thenAnswer((_) async => 1);
    
    // 开始测试目标方法前记录状态
    expect(provider.allTasks.length, 0);
    
    // 调用目标方法
    await provider.addTask(task);
    
    // 验证结果
    verify(mockDb.insertTask(any)).called(1);
    expect(provider.allTasks.length, 1);
    expect(provider.allTasks.first.id, '1');
  });
}
```

### 2.3 工具类测试

对工具类和辅助函数测试各种输入条件下的行为：

```dart
group('Date Utils Tests', () {
  test('isSameDay returns true for dates with same day', () {
    final date1 = DateTime(2023, 5, 15, 9, 0);
    final date2 = DateTime(2023, 5, 15, 18, 30);
    expect(DateUtils.isSameDay(date1, date2), true);
  });
  
  test('isSameDay returns false for different days', () {
    final date1 = DateTime(2023, 5, 15);
    final date2 = DateTime(2023, 5, 16);
    expect(DateUtils.isSameDay(date1, date2), false);
  });
  
  test('formatChineseDateWithWeekday formats date correctly', () {
    final date = DateTime(2023, 5, 15); // 星期一
    expect(
      DateUtils.formatChineseDateWithWeekday(date),
      '5月15日 星期一'
    );
  });
});
```

## 3. 小部件测试实现

### 3.1 独立组件测试策略

对UI组件测试以下方面：
- 组件渲染
- 用户交互响应
- 状态变化导致的UI更新
- 边界条件（例如长文本、空数据）

#### TaskListItem测试示例：

```dart
testWidgets('TaskListItem shows task details correctly', (WidgetTester tester) async {
  // 构建测试组件
  final task = Task(
    id: '1',
    title: 'Test Task',
    notes: 'Test notes',
    priority: TaskPriority.high,
    dueDate: DateTime.now(),
    createdAt: DateTime.now(),
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TaskListItem(task: task),
      ),
    ),
  );
  
  // 验证组件包含正确的信息
  expect(find.text('Test Task'), findsOneWidget);
  expect(find.text('Test notes'), findsOneWidget);
  
  // 验证优先级图标显示正确
  expect(find.byIcon(Icons.flag), findsOneWidget);
  
  // 测试交互：点击完成按钮
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
  
  // 验证任务完成状态发生变化
  // 注意：在实际测试中需要模拟Provider以验证状态变化
});
```

### 3.2 与Provider结合的组件测试

测试UI组件与Provider交互：

```dart
testWidgets('TaskListItem updates when task is completed', (WidgetTester tester) async {
  // 创建模拟Provider
  final mockProvider = MockTaskProvider();
  final task = Task(
    id: '1',
    title: 'Test Task',
    status: TaskStatus.notStarted,
    createdAt: DateTime.now(),
  );
  
  // 设置Provider行为
  when(mockProvider.toggleTaskStatus(any)).thenAnswer((_) async {
    // 模拟任务状态切换
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    return updatedTask;
  });
  
  // 构建测试组件
  await tester.pumpWidget(
    ChangeNotifierProvider<TaskProvider>.value(
      value: mockProvider,
      child: MaterialApp(
        home: Scaffold(
          body: TaskListItem(task: task),
        ),
      ),
    ),
  );
  
  // 执行交互
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
  
  // 验证Provider方法被调用
  verify(mockProvider.toggleTaskStatus(any)).called(1);
  
  // 验证UI更新
  // 注意：UI更新依赖于Provider返回的值和通知机制
});
```

### 3.3 屏幕测试策略

对应用页面进行测试：

```dart
testWidgets('CalendarScreen shows today\'s tasks', (WidgetTester tester) async {
  // 模拟Provider和任务数据
  final mockTaskProvider = MockTaskProvider();
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  
  final tasks = [
    Task(id: '1', title: 'Today Task 1', dueDate: today, createdAt: DateTime.now()),
    Task(id: '2', title: 'Today Task 2', dueDate: today, createdAt: DateTime.now()),
  ];
  
  // 设置Provider返回今天的任务
  when(mockTaskProvider.allTasks).thenReturn(tasks);
  when(mockTaskProvider.getTasksForDay(any)).thenReturn(tasks);
  
  // 构建测试页面
  await tester.pumpWidget(
    ChangeNotifierProvider<TaskProvider>.value(
      value: mockTaskProvider,
      child: MaterialApp(
        home: CalendarScreen(),
      ),
    ),
  );
  
  // 验证任务列表显示了正确的任务
  expect(find.text('Today Task 1'), findsOneWidget);
  expect(find.text('Today Task 2'), findsOneWidget);
  
  // 测试日历交互
  // 添加日历特定交互测试...
});
```

## 4. 集成测试实现

### 4.1 应用流程测试

测试完整的用户操作流程：

```dart
testWidgets('Create task flow', (WidgetTester tester) async {
  // 启动应用
  app.main();
  await tester.pumpAndSettle();
  
  // 导航到收件箱页面
  await tester.tap(find.byIcon(Icons.inbox));
  await tester.pumpAndSettle();
  
  // 点击添加任务按钮
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  
  // 填写任务表单
  await tester.enterText(find.byType(TextField).first, '集成测试任务');
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
  
  // 验证任务已添加到列表
  expect(find.text('集成测试任务'), findsOneWidget);
  
  // 测试任务完成功能
  await tester.tap(find.byType(Checkbox).first);
  await tester.pumpAndSettle();
  
  // 验证任务状态已更新
  // 这需要依赖于UI中任务完成后的视觉变化进行验证
});
```

### 4.2 黑盒集成测试

从用户角度测试应用的整体功能：

```dart
testWidgets('App maintains state across restarts', (WidgetTester tester) async {
  // 首次启动应用
  app.main();
  await tester.pumpAndSettle();
  
  // 创建任务
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, '持久化测试任务');
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
  
  // 验证任务创建成功
  expect(find.text('持久化测试任务'), findsOneWidget);
  
  // 模拟应用重启
  await tester.pumpWidget(app.MyApp());
  await tester.pumpAndSettle();
  
  // 导航到相同页面
  await tester.tap(find.byIcon(Icons.inbox));
  await tester.pumpAndSettle();
  
  // 验证任务数据被保留
  expect(find.text('持久化测试任务'), findsOneWidget);
});
```

### 4.3 性能集成测试

测试应用在各种条件下的性能：

```dart
testWidgets('App handles large task list smoothly', (WidgetTester tester) async {
  // 设置性能跟踪
  final binding = tester.binding as IntegrationTestWidgetsFlutterBinding;
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  
  // 启动应用
  app.main();
  await tester.pumpAndSettle();
  
  // 导航到任务列表页面
  await tester.tap(find.byIcon(Icons.inbox));
  await tester.pumpAndSettle();
  
  // 开始性能跟踪
  await binding.traceAction(() async {
    // 执行滚动操作
    final listFinder = find.byType(ListView);
    for (int i = 0; i < 20; i++) {
      await tester.drag(listFinder, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }, reportKey: 'scrolling_performance');
});
```

## 5. 高级测试技术

### 5.1 Golden测试

使用Golden测试验证UI外观：

```dart
testWidgets('TaskListItem matches golden file', (WidgetTester tester) async {
  // 构建小部件
  final task = Task(
    id: '1',
    title: 'Golden Test Task',
    priority: TaskPriority.high,
    createdAt: DateTime.now(),
  );
  
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: TaskListItem(task: task),
      ),
    ),
  );
  
  // 比较与黄金文件
  await expectLater(
    find.byType(TaskListItem),
    matchesGoldenFile('goldens/task_list_item.png'),
  );
});

// 同样的组件在黑暗模式下测试
testWidgets('TaskListItem matches golden file in dark mode', (WidgetTester tester) async {
  // 类似上面，但使用ThemeData.dark()
});
```

### 5.2 测试不同语言和区域设置

```dart
testWidgets('App displays Chinese text correctly', (WidgetTester tester) async {
  // 构建使用中文区域设置的应用
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: [
        // 添加相关代理
      ],
      home: MyHomePage(),
    ),
  );
  
  // 验证UI元素显示正确的中文文本
  expect(find.text('收件箱'), findsOneWidget);
  expect(find.text('今天'), findsOneWidget);
});
```

### 5.3 测试数据库迁移

```dart
test('Database migration handles schema changes', () async {
  // 创建旧版本数据库
  final oldDb = await createOldVersionDatabase();
  
  // 向旧数据库添加测试数据
  await oldDb.insert('tasks', {'id': '1', 'title': 'Old Task'});
  
  // 执行迁移
  final newDb = await migrateDatabase(oldDb);
  
  // 验证数据被正确迁移
  final tasks = await newDb.query('tasks');
  expect(tasks.length, 1);
  expect(tasks.first['title'], 'Old Task');
  expect(tasks.first.containsKey('new_column'), true);
});
```

## 6. 测试自动化

### 6.1 CI/CD集成

将测试集成到CI/CD流程中：

```yaml
# .github/workflows/flutter.yml 或类似CI配置

name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test integration_test/app_test.dart
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v1
```

### 6.2 测试覆盖率监控

监控和改进测试覆盖率：

```bash
# 运行测试并生成覆盖率报告
flutter test --coverage

# 生成HTML格式的覆盖率报告
genhtml coverage/lcov.info -o coverage/html

# 打开报告
open coverage/html/index.html
```

### 6.3 自动化测试脚本

项目提供了以下自动化测试脚本，位于`scripts/`目录下：

#### 6.3.1 主要测试脚本

1. **全面测试套件**
   ```bash
   ./scripts/run_all_tests.sh
   ```
   运行所有类型的测试，包括静态分析、单元测试和端到端测试。自动检测连接的设备类型，并使用相应的测试脚本。

2. **单元测试**
   ```bash
   ./scripts/run_unit_tests.sh
   ```
   运行所有单元测试并生成覆盖率报告。报告存储在`test_results/unit_tests/`目录下。

3. **静态代码分析**
   ```bash
   ./scripts/run_static_analysis.sh
   ```
   运行代码分析、格式检查和依赖检查，帮助维护代码质量。

4. **端到端测试**
   ```bash
   ./scripts/run_e2e_tests.sh [设备ID]
   ```
   在指定设备上运行所有集成测试。如果未指定设备ID，将尝试使用第一个可用设备。

#### 6.3.2 设备特定测试脚本

1. **Android设备测试**
   ```bash
   ./scripts/run_android_tests.sh
   ```
   自动检测连接的Android设备并在其上运行端到端测试。

2. **iOS设备测试**
   ```bash
   ./scripts/run_ios_tests.sh
   ```
   自动检测连接的iOS设备并在其上运行端到端测试。

#### 6.3.3 使用说明

1. 首先确保脚本有执行权限：
   ```bash
   chmod +x scripts/*.sh
   ```

2. 运行全面测试：
   ```bash
   ./scripts/run_all_tests.sh
   ```

3. 查看测试结果：
   - 单元测试结果位于：`test_results/unit_tests/[时间戳]/`
   - 端到端测试结果位于：`test_results/[时间戳]/`

4. 所有测试脚本将使用颜色编码输出，方便快速识别通过（绿色）和失败（红色）的测试。

## 7. 测试改进规划

### 7.1 当前测试的不足

1. **依赖注入问题**：Provider直接使用单例实例，导致测试难以隔离
2. **小部件测试不完整**：需要更全面的UI组件测试
3. **集成测试覆盖率低**：关键用户流程未完全覆盖
4. **缺少性能测试**：未测试应用在大量数据下的性能

### 7.2 短期改进计划

1. **重构Provider**：实现依赖注入模式
2. **增加模型测试**：补充Project和Tag模型的完整测试
3. **添加小部件测试**：完善TaskListItem和其他关键组件的测试
4. **实现基本集成测试**：添加核心用户流程的测试

### 7.3 长期改进计划

1. **实现Golden测试**：验证UI外观一致性
2. **添加性能测试**：测试不同数据量下的应用性能
3. **多语言测试**：确保国际化支持的正确性
4. **自动化测试流程**：集成到CI/CD流程

## 8. 参考资源

### 8.1 Flutter测试文档

- [Flutter测试介绍](https://flutter.dev/docs/testing)
- [单元测试](https://flutter.dev/docs/cookbook/testing/unit)
- [小部件测试](https://flutter.dev/docs/cookbook/testing/widget)
- [集成测试](https://flutter.dev/docs/testing/integration-tests)

### 8.2 测试工具

- [Mockito](https://pub.dev/packages/mockito)
- [Fake](https://api.flutter.dev/flutter/flutter_test/Fake-class.html)
- [Golden测试](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html) 