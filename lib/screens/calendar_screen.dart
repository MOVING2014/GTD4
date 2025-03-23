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
        title: const Text('日历视图'),
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
                color: Color(0xFF5D69B3),
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
            // 自定义标记为数字
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  // 计算未完成任务数量
                  final uncompletedTasks = events.where((task) => 
                    task is Task && task.status != TaskStatus.completed).toList();
                  
                  if (uncompletedTasks.isEmpty) return const SizedBox.shrink();
                  
                  // 显示数字而不是小点
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D69B3),
                      shape: BoxShape.circle,
                    ),
                    width: 13,
                    height: 13,
                    child: Center(
                      child: Text(
                        uncompletedTasks.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
              // 自定义星期几的标题
              dowBuilder: (context, day) {
                final text = const ['日', '一', '二', '三', '四', '五', '六'][day.weekday % 7];
                return Center(
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              },
              // 自定义月份标题显示
              headerTitleBuilder: (context, month) {
                // 直接使用中文年月格式，不使用DateFormat
                final formattedMonth = '${month.year}年${month.month}月';
                return Center(
                  child: Text(
                    formattedMonth,
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            // 自定义格式切换按钮
            availableCalendarFormats: const {
              CalendarFormat.month: '月',
              CalendarFormat.week: '周',
            },
            // 设置月份格式
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16.0),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.black87),
              formatButtonPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            ),
            // 不设置国际化locale，但自定义显示元素
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
          
          // 添加分割线
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Divider(
              height: 0,
              thickness: 0.5,
              color: Color(0xFFDDDDDD),
              indent: 16.0,
              endIndent: 16.0,
            ),
          ),
          
          // 选中日期的任务
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isSameDay(_selectedDay, DateTime.now()) 
                        ? '今天' 
                        : _formatChineseDate(_selectedDay),
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
                                '${_formatChineseDate(_selectedDay)} 没有任务',
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
                            child: Text(
                              '逾期任务 (${overdueTasks.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
                            child: Text(
                              '任务 (${dateTasks.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
        backgroundColor: const Color(0xFF5D69B3),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // 将日期格式化为中文格式
  String _formatChineseDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
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