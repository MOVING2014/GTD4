import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/settings_button.dart';

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
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历视图'),
        actions: [
          // 显示/隐藏已完成任务的过滤器按钮
          IconButton(
            icon: Icon(
              taskProvider.showCompletedTasks 
                  ? Icons.check_circle_outline 
                  : Icons.check_circle,
              color: taskProvider.showCompletedTasks 
                  ? theme.colorScheme.onSurface.withOpacity(0.5) 
                  : Colors.green,
            ),
            tooltip: taskProvider.showCompletedTasks ? '隐藏已完成任务' : '显示已完成任务',
            onPressed: () {
              taskProvider.toggleShowCompletedTasks();
            },
          ),
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
          const SettingsButton(),
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
              // 排除当天，让 todayBuilder 完全控制今天的样式
              return isSameDay(_selectedDay, day) && !isSameDay(day, DateTime.now());
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
            calendarStyle: CalendarStyle(
              // 适配暗黑模式的日历样式
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                // 确保内置的今天装饰完全透明
                border: Border.all(color: Colors.transparent, width: 0),
              ),
              todayTextStyle: TextStyle(
                color: isDarkMode ? Colors.orange : Colors.red,  // 暗黑模式下用橙色，亮色模式用红色
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
              selectedDecoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              selectedTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
              // 调整默认文本颜色为主题适配
              defaultTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
              // 周末文本颜色适配
              weekendTextStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              // 日历外部日期文本颜色
              outsideTextStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              // 标记样式
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    width: 13,
                    height: 13,
                    child: Center(
                      child: Text(
                        uncompletedTasks.length.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
              // 自定义今天的日期单元格，确保今天的日期样式优先于选中的日期样式
              todayBuilder: (context, day, focusedDay) {
                final isSelected = isSameDay(day, _selectedDay);
                
                return Center(
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 使用淡绿色代替淡橙色，透明度为0.3
                      color: isDarkMode 
                          ? Colors.green.shade100.withOpacity(0.3) 
                          : Colors.red.shade100.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          // 使用主题的primary color
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
              // 自定义选中的日期单元格
              selectedBuilder: (context, day, focusedDay) {
                // 如果选中的日期是今天，让todayBuilder处理
                if (isSameDay(day, DateTime.now())) return null;
                
                return Center(
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
              // 自定义星期几的标题
              dowBuilder: (context, day) {
                final text = const ['日', '一', '二', '三', '四', '五', '六'][day.weekday % 7];
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
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
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
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
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(16.0),
              ),
              formatButtonTextStyle: TextStyle(color: theme.colorScheme.onSurface),
              formatButtonPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              // 调整标题颜色
              titleTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17.0,
                fontWeight: FontWeight.bold,
              ),
              // 调整左右箭头颜色
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: theme.colorScheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface,
              ),
            ),
            // 不设置国际化locale，但自定义显示元素
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
          
          // 添加分割线
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              height: 0,
              thickness: 0.5,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
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
                    _formatChineseDate(_selectedDay),
                    style: theme.textTheme.titleLarge,
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
                                color: theme.colorScheme.onSurface.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_formatChineseDate(_selectedDay).trim()} 没有任务',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                        // 直接添加逾期任务项，移除标题
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
                        // 直接添加当日任务项，移除标题
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
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }
  
  // 将日期格式化为中文格式
  String _formatChineseDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    String prefix = '';
    
    // 使用日期比较
    if (selectedDate.year == yesterday.year && 
        selectedDate.month == yesterday.month && 
        selectedDate.day == yesterday.day) {
      prefix = '昨天 - ';
    } else if (selectedDate.year == today.year && 
               selectedDate.month == today.month && 
               selectedDate.day == today.day) {
      prefix = '今天 - ';
    } else if (selectedDate.year == tomorrow.year && 
               selectedDate.month == tomorrow.month && 
               selectedDate.day == tomorrow.day) {
      prefix = '明天 - ';
    }
    
    return '$prefix${date.month}月${date.day}日 周${['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7]}';
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = taskProvider.getTasksForDate(day);
    return tasks;
  }
  
  Future<void> _addTaskForSelectedDay() async {
    // 使用弹窗创建当前选中日期的新任务
    final result = await showAddTaskDialog(
      context,
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
    );
    
    // 如果返回true，表示添加/编辑了任务，需要刷新页面
    if (result == true) {
      setState(() {});
    }
  }
} 