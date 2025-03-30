import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/priority_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/review_screen.dart';
import 'data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统UI为沉浸式，使系统导航栏完全透明
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    // 透明的系统导航栏
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    // 透明的状态栏
    statusBarColor: Colors.transparent,
    // 不在这里设置固定的图标亮度，而是在MyApp中根据主题动态设置
  ));
  
  // 启用边缘到边缘显示模式，让应用内容扩展到系统栏区域
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Todo',
            // 使用ThemeProvider中的主题模式设置
            themeMode: themeProvider.themeMode,
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
                // 自定义暗色主题的背景色为更深的黑蓝色
                background: const Color(0xFF020810),
                surface: const Color(0xFF030C14),
                // 稍微调整其他颜色，保持协调
                onBackground: const Color(0xFFE1E9F4),
                onSurface: const Color(0xFFE1E9F4),
              ),
              // 设置AppBar样式
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              // 设置Scaffold默认背景色
              scaffoldBackgroundColor: const Color(0xFF020810),
              // 调整卡片和对话框背景
              cardColor: const Color(0xFF030C14), 
              dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF030C14)),
            ),
            // 在主题应用后设置系统UI样式
            builder: (context, child) {
              // 根据当前主题亮度调整系统导航栏图标亮度
              final brightness = Theme.of(context).brightness;
              
              // 使用延迟执行，确保UI样式在渲染完成后应用
              Future.microtask(() {
                SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                  // 确保系统导航栏完全透明
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  // 根据当前主题调整图标亮度
                  systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
                  // 同样调整状态栏图标
                  statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
                  statusBarBrightness: brightness,
                  // 确保状态栏也是透明的
                  statusBarColor: Colors.transparent,
                ));
              });
              
              return child!;
            },
            home: const HomeScreen(),
          );
        }
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
    final theme = Theme.of(context);
    
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
      // 设置背景透明以便系统手势条能够更好地融入
      backgroundColor: theme.scaffoldBackgroundColor,
      // 确保Scaffold是透明的
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Container(
        // 添加一个额外的容器来包裹导航栏，便于自定义
        decoration: BoxDecoration(
          // 完全透明，没有颜色和边框
          color: Colors.transparent,
        ),
        child: NavigationBar(
          // 增加底部填充，确保导航栏不会与系统手势区重叠
          height: kBottomNavigationBarHeight + bottomPadding,
          // 设置导航栏背景透明
          backgroundColor: Colors.transparent,
          // 去掉阴影
          elevation: 0,
          // 导航指示器颜色根据主题调整
          indicatorColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
          // 导航项颜色根据主题调整
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.calendar_today, color: Colors.pink),
              selectedIcon: Icon(Icons.calendar_today, color: Colors.pink),
              label: '日历',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: taskProvider.inboxTasksCount > 0,
                label: Text(taskProvider.inboxTasksCount.toString()),
                child: Icon(Icons.inbox, color: Colors.grey),
              ),
              selectedIcon: Badge(
                isLabelVisible: taskProvider.inboxTasksCount > 0,
                label: Text(taskProvider.inboxTasksCount.toString()),
                child: Icon(Icons.inbox, color: Colors.grey),
              ),
              label: '收件箱',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: taskProvider.getPrioritizedTasksCount() > 0,
                label: Text(taskProvider.getPrioritizedTasksCount().toString()),
                child: Icon(Icons.flag, color: Colors.orange),
              ),
              selectedIcon: Badge(
                isLabelVisible: taskProvider.getPrioritizedTasksCount() > 0,
                label: Text(taskProvider.getPrioritizedTasksCount().toString()),
                child: Icon(Icons.flag, color: Colors.orange),
              ),
              label: '优先任务',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_books, color: Colors.blue),
              selectedIcon: Icon(Icons.library_books, color: Colors.blue),
              label: '项目',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: projectsNeedingReview.isNotEmpty,
                label: Text(projectsNeedingReview.length.toString()),
                child: Icon(Icons.history, color: Colors.indigo),
              ),
              selectedIcon: Badge(
                isLabelVisible: projectsNeedingReview.isNotEmpty,
                label: Text(projectsNeedingReview.length.toString()),
                child: Icon(Icons.history, color: Colors.indigo),
              ),
              label: '回顾',
            ),
          ],
        ),
      ),
    );
  }
}
