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
                  child: Text(
                    AppDateUtils.formatDate(_selectedDay),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                
                // 使用 Expanded + ListView 让任务列表可滚动
                Expanded(
                  child: Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      final overdueTasks = isSameDay(_selectedDay, DateTime.now()) 
                          ? taskProvider.overdueTasks
                          : <Task>[];
                      final dateTasks = taskProvider.getTasksForDate(_selectedDay);
                      
                      if (overdueTasks.isEmpty && dateTasks.isEmpty) {
                        // 如果没有任务，显示空状态
                        return Center(
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
                                'No tasks for ${AppDateUtils.formatDate(_selectedDay)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // 构建任务列表项
                      final listItems = <Widget>[];
                      
                      // 添加逾期任务
                      if (overdueTasks.isNotEmpty) {
                        listItems.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Overdue (${overdueTasks.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        // 添加逾期任务项
                        for (final task in overdueTasks) {
                          listItems.add(
                            TaskListItem(
                              task: task,
                              onTaskChange: () => setState(() {}),
                            ),
                          );
                        }
                      }
                      
                      // 添加当日任务
                      if (dateTasks.isNotEmpty) {
                        listItems.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tasks (${dateTasks.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        // 添加当日任务项
                        for (final task in dateTasks) {
                          listItems.add(
                            TaskListItem(
                              task: task,
                              onTaskChange: () => setState(() {}),
                            ),
                          );
                        }
                      }
                      
                      return ListView(
                        children: listItems,
                      );
                    },
                  ),
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
} 