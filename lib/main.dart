import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/project_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/priority_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/review_screen.dart';
import 'data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统UI为沉浸式，使系统导航栏透明
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    // 根据平台亮度动态调整图标亮度
    systemNavigationBarIconBrightness: Brightness.dark, 
  ));
  
  // 启用边缘到边缘显示模式，让应用内容扩展到系统栏区域
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // 确保数据库已初始化
  await DatabaseHelper.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'GTD应用',
        // 使用系统的亮暗模式设置
        themeMode: ThemeMode.system,
        // 亮色主题
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D69B3),
            brightness: Brightness.light,
          ),
          // 设置AppBar样式
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        // 暗色主题
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D69B3),
            brightness: Brightness.dark,
          ),
          // 设置AppBar样式
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _pages = [
    CalendarScreen(),
    InboxScreen(),
    PriorityScreen(),
    ProjectsScreen(),
    ReviewScreen(),
  ];
  
  static const List<String> _titles = [
    '日历',
    '收件箱',
    '优先任务',
    '项目',
    '回顾',
  ];
  
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projectsNeedingReview = projectProvider.projectsNeedingReview;
    
    // 获取底部安全区域的高度
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 获取当前主题亮暗模式状态
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      // 使用SafeArea确保内容不会被底部导航手势区遮挡
      body: SafeArea(
        // 只应用底部的SafeArea，顶部和侧面不需要
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        // 增加底部填充，确保导航栏不会与系统手势区重叠
        height: kBottomNavigationBarHeight + bottomPadding,
        // 设置导航栏背景透明，使用上下文主题
        backgroundColor: Colors.transparent,
        // 暗色模式下调整标签和图标颜色
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: taskProvider.inboxTasksCount > 0,
              label: Text(taskProvider.inboxTasksCount.toString()),
              child: const Icon(Icons.inbox),
            ),
            label: '收件箱',
          ),
          const NavigationDestination(
            icon: Icon(Icons.priority_high),
            label: '优先任务',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder),
            label: '项目',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: projectsNeedingReview.isNotEmpty,
              child: const Icon(Icons.history),
            ),
            label: '回顾',
          ),
        ],
      ),
    );
  }
}
