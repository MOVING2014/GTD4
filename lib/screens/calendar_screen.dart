import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../screens/task_form_screen.dart';
import '../utils/date_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda),
            onPressed: () {
              setState(() {
                if (_calendarFormat == CalendarFormat.month) {
                  _calendarFormat = CalendarFormat.week;
                } else {
                  _calendarFormat = CalendarFormat.month;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // 创建当前选中日期的新任务
              await _addTaskForSelectedDay();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日历组件
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            // 添加任务标记点
            eventLoader: (day) {
              return _getEventsForDay(day);
            },
          ),
          
          // 选中日期的任务
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppDateUtils.formatDate(_selectedDay),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      OutlinedButton.icon(
                        onPressed: _addTaskForSelectedDay,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                      ),
                    ],
                  ),
                ),
                
                // 逾期任务（如果查看当天）
                if (isSameDay(_selectedDay, DateTime.now()))
                  _buildTaskSection(
                    context, 
                    'Overdue', 
                    Colors.red, 
                    (provider) => provider.overdueTasks,
                  ),
                
                // 选中日期的任务
                _buildTaskSection(
                  context,
                  'Tasks',
                  Colors.blue,
                  (provider) => provider.getTasksForDate(_selectedDay),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTaskForSelectedDay,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = taskProvider.getTasksForDate(day);
    return tasks;
  }
  
  Future<void> _addTaskForSelectedDay() async {
    // 创建带有当前选中日期的新任务
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(
          task: Task(
            id: 't${DateTime.now().millisecondsSinceEpoch}',
            title: '',
            dueDate: DateTime(
              _selectedDay.year,
              _selectedDay.month,
              _selectedDay.day,
            ),
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
    
    // 如果返回true，表示添加/编辑了任务，需要刷新页面
    if (result == true) {
      setState(() {});
    }
  }
  
  Widget _buildTaskSection(
    BuildContext context,
    String title,
    Color color,
    List<Task> Function(TaskProvider) tasksSelector,
  ) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = tasksSelector(taskProvider);
        
        if (tasks.isEmpty) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks for $title',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (title != 'Overdue')
                    ElevatedButton.icon(
                      onPressed: _addTaskForSelectedDay,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                    ),
                ],
              ),
            ),
          );
        }
        
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$title (${tasks.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskListItem(
                      task: tasks[index],
                      onTaskChange: () {
                        // 任务状态变化后刷新页面
                        setState(() {});
                      }
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 