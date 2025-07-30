import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
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
  
  // 仅在移动平台设置系统UI样式
  if (!Platform.isMacOS) {
    // 设置系统UI为沉浸式，使系统导航栏完全透明
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      // 透明的系统导航栏
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      // 透明的状态栏
      statusBarColor: Colors.transparent,
      // 不在这里设置固定的图标亮度，而是在MyApp中根据主题动态设置
    ));
    
    // 默认使用边缘到边缘显示模式
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  
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
                surface: const Color(0xFF020810),
                surfaceContainerHighest: const Color(0xFF030C14),
                // 稍微调整其他颜色，保持协调
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
              
              // 仅在移动平台设置系统UI样式
              if (!Platform.isMacOS) {
                // 使用延迟执行，确保UI样式在渲染完成后应用
                Future.microtask(() {
                  // 应用系统UI样式，但不改变导航栏显示状态（由ThemeProvider控制）
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
              }
              
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
  
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projectsNeedingReview = projectProvider.projectsNeedingReview;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // 获取底部安全区域的高度
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 获取当前主题亮暗模式状态
    final theme = Theme.of(context);
    
    // 判断是否为桌面平台
    final isMacOS = Platform.isMacOS;
    
    // macOS平台下的标题栏安全区域高度
    final topPadding = isMacOS ? 28.0 : 0.0;
    
    // 创建macOS适用的侧边导航栏
    Widget? navigationRail;
    if (isMacOS) {
      navigationRail = Padding(
        // 为侧边导航栏添加顶部填充，避免与窗口控制按钮重叠
        padding: EdgeInsets.only(top: topPadding),
        child: NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.all,
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
          destinations: [
            NavigationRailDestination(
              icon: Icon(Icons.calendar_today, color: Colors.pink),
              selectedIcon: Icon(Icons.calendar_today, color: Colors.pink),
              label: Text('日历'),
            ),
            NavigationRailDestination(
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
              label: Text('收件箱'),
            ),
            NavigationRailDestination(
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
              label: Text('优先任务'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.library_books, color: Colors.blue),
              selectedIcon: Icon(Icons.library_books, color: Colors.blue),
              label: Text('项目'),
            ),
            NavigationRailDestination(
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
              label: Text('回顾'),
            ),
          ],
        ),
      );
    }
    
    return GestureDetector(
      // 添加上滑手势以临时显示系统UI（仅当导航栏被隐藏时有效，且不在macOS上）
      onVerticalDragEnd: (!isMacOS && themeProvider.hideNavigationBar) ? (details) {
        if (details.velocity.pixelsPerSecond.dy < -300) {
          // 向上滑动显示系统UI
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );
          // 3秒后再次隐藏
          Future.delayed(const Duration(seconds: 3), () {
            if (themeProvider.hideNavigationBar) {
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.immersiveSticky,
                overlays: [],
              );
            }
          });
        }
      } : null,
      child: Scaffold(
        // 使用SafeArea确保内容不会被底部导航手势区遮挡
        body: SafeArea(
          // 仅在非macOS平台应用底部的SafeArea
          top: false,
          left: false,
          right: false,
          bottom: !isMacOS,
          child: isMacOS 
              ? Row(
                  children: [
                    // macOS的侧边导航栏
                    navigationRail!,
                    // 内容区域，添加顶部内边距防止与窗口控制按钮重叠
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: topPadding),
                        child: _pages[_selectedIndex],
                      ),
                    ),
                  ],
                )
              : _pages[_selectedIndex],
        ),
        // 设置背景透明以便系统手势条能够更好地融入
        backgroundColor: theme.scaffoldBackgroundColor,
        // 确保Scaffold是透明的
        extendBody: true,
        extendBodyBehindAppBar: true,
        // 仅在非macOS平台显示底部导航栏
        bottomNavigationBar: !isMacOS ? Container(
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
            indicatorColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
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
        ) : null,
      ),
    );
  }
}
