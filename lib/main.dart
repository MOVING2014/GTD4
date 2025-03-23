import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/project_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/inbox_screen.dart';

void main() {
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
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
    ProjectsScreen(),
  ];
  
  static const List<String> _titles = [
    '日历',
    '收件箱',
    '项目',
  ];
  
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(Icons.folder),
            label: '项目',
          ),
        ],
      ),
    );
  }
}
