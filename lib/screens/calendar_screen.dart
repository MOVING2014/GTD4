import 'package:flutter/material.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _activeColumnType = '今天';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _focusedDay = _selectedDay;
  }

  // Helper to get uncompleted tasks for a specific date
  int _getUncompletedTasksForDate(BuildContext context, DateTime date) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    return taskProvider.getTasksForDate(date).where((task) => task.status != TaskStatus.completed).length;
  }

  // Helper to get uncompleted tasks due after a specific future date
  int _getUncompletedFurtherFutureTasks(BuildContext context, DateTime afterDate) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    return taskProvider.allTasks.where((task) =>
        task.status != TaskStatus.completed &&
        task.dueDate != null &&
        task.dueDate!.isAfter(afterDate) // Strictly after the given date
    ).length;
  }

  Widget _buildCustomDOWHeader(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Map<String, dynamic>> headerItems = [];

    // 1. Past Column
    headerItems.add({
      'id': '过去', // Unique ID for managing active state
      'label_top': '过去',
      'label_bottom': taskProvider.overdueTasks.where((t) => t.status != TaskStatus.completed).length.toString(),
      'target_day': today, // Tapping Past focuses Today for list title context
      'is_past_column': true,
    });

    // 2. Today Column
    headerItems.add({
      'id': '今天',
      'label_top': '今天',
      'label_bottom': _getUncompletedTasksForDate(context, today).toString(),
      'target_day': today,
      'is_today_column': true,
    });

    // 3-6. Four Future Dates Columns
    for (int i = 1; i <= 4; i++) {
      final date = today.add(Duration(days: i));
      final label = '${date.day} 周${['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7]}';
      headerItems.add({
        'id': label, // Use the label as a unique ID for these columns
        'label_top': label,
        'label_bottom': _getUncompletedTasksForDate(context, date).toString(),
        'target_day': date,
      });
    }

    // 7. Further Future Column
    final fourDaysAhead = today.add(const Duration(days: 4));
    headerItems.add({
      'id': '将来',
      'label_top': '将来',
      'label_bottom': _getUncompletedFurtherFutureTasks(context, fourDaysAhead).toString(),
      'target_day': today.add(const Duration(days: 5)), // Focus day after the 4 explicitly shown
    });

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0, bottom: 0.0),
      child: Row(
        children: headerItems.map((item) {
          final String itemId = item['id']! as String;
          bool isActiveColumn = _activeColumnType == itemId;
          bool isTodayColumn = item['is_today_column'] ?? false;
          bool isPastColumn = item['is_past_column'] ?? false;
          Color labelTopColor;
          FontWeight labelTopFontWeight = FontWeight.normal;

          if (isTodayColumn) {
            labelTopColor = theme.colorScheme.primary;
            labelTopFontWeight = FontWeight.bold;
          } else if (isActiveColumn) {
            labelTopColor = theme.colorScheme.primary;
          } else {
            labelTopColor = theme.colorScheme.onSurface.withOpacity(0.85);
          }
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeColumnType = itemId;
                  _selectedDay = item['target_day']! as DateTime;
                  _focusedDay = _selectedDay;
                });
              },
              child: Container(
                padding: const EdgeInsets.only(top: 2.0, bottom: 6.0, left: 2.0, right: 2.0),
                decoration: BoxDecoration(
                  color: isActiveColumn ? theme.colorScheme.onSurface.withOpacity(0.08) : null,
                  border: Border(top: BorderSide(
                    color: isActiveColumn ? theme.colorScheme.onSurface.withOpacity(0.5) : Colors.transparent,
                    width: 2.0
                  )),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['label_top']! as String,
                      style: TextStyle(
                        fontWeight: labelTopFontWeight,
                        fontSize: 11,
                        color: labelTopColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label_bottom']! as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isTodayColumn ? FontWeight.bold : FontWeight.normal,
                        color: isPastColumn
                            ? Colors.red.shade400
                            : (isTodayColumn && item['label_bottom']! as String == '0')
                                ? theme.colorScheme.onSurface.withOpacity(0.3)
                                : (isActiveColumn
                                    ? theme.colorScheme.primary.withOpacity(0.9)
                                    : theme.colorScheme.onSurface.withOpacity(isTodayColumn ? 0.7 : 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '预测',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.pink,
            fontSize: 34.0,
          ),
        ),
        actions: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) => IconButton(
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
          ),
          const SettingsButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomDOWHeader(context),
          Divider(
            height: 0,
            thickness: 0.5,
            color: theme.colorScheme.onSurface.withOpacity(0.15),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text(
              _activeColumnType == '过去' ? '已逾期任务' : _activeColumnType == '将来' ? '未来任务' : _formatChineseDate(_selectedDay),
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                List<Task> tasksToDisplay = [];
                String emptyListMessage = '没有任务';

                switch (_activeColumnType) {
                  case '过去':
                    tasksToDisplay = taskProvider.overdueTasks
                        .where((t) => taskProvider.showCompletedTasks || t.status != TaskStatus.completed).toList();
                    emptyListMessage = '没有已逾期任务';
                    break;
                  case '今天':
                  // For specific date columns, _activeColumnType will be like '24 周四'
                  // So we need to handle these by checking if _activeColumnType is NOT '过去' or '将来'
                  // The _selectedDay is already correctly set by the header tap for these.
                    tasksToDisplay = taskProvider.getTasksForDate(_selectedDay)
                        .where((t) => taskProvider.showCompletedTasks || t.status != TaskStatus.completed).toList();
                    emptyListMessage = '${_formatChineseDate(_selectedDay).split(' - ').lastOrDefault('')} 没有任务';
                    break;
                  case '将来':
                    final fourDaysAhead = DateTime.now().add(const Duration(days: 4));
                    tasksToDisplay = taskProvider.allTasks
                        .where((task) =>
                            (taskProvider.showCompletedTasks || task.status != TaskStatus.completed) &&
                            task.dueDate != null &&
                            task.dueDate!.isAfter(fourDaysAhead)
                        ).toList();
                    tasksToDisplay.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
                    emptyListMessage = '未来没有任务';
                    break;
                  default: // Handles specific date columns like '24 周四' etc.
                     tasksToDisplay = taskProvider.getTasksForDate(_selectedDay)
                        .where((t) => taskProvider.showCompletedTasks || t.status != TaskStatus.completed).toList();
                    emptyListMessage = '${_formatChineseDate(_selectedDay).split(' - ').lastOrDefault('')} 没有任务';
                    break;
                }

                if (tasksToDisplay.isEmpty) {
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
                          emptyListMessage,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: tasksToDisplay.length,
                  itemBuilder: (context, index) {
                    final task = tasksToDisplay[index];
                    return TaskListItem(
                      task: task,
                      onTaskChange: () => setState(() {}),
                      hideProjectLabel: _activeColumnType == '将来',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          DateTime taskDueDate = _selectedDay;
          if (_activeColumnType == '过去') {
            taskDueDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          } else if (_activeColumnType == '将来') {
            taskDueDate = _selectedDay;
          }

          final result = await showAddTaskDialog(
            context,
            task: Task(
              id: 't${DateTime.now().millisecondsSinceEpoch}',
              title: '',
              dueDate: taskDueDate,
              createdAt: DateTime.now(),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
  
  String _formatChineseDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    String prefix = '';
    
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
    } else if (date.isBefore(today)) {
        prefix = '过去 - ';
    } else if (date.isAfter(tomorrow)) {
        prefix = '将来 - ';
    }
    
    return '$prefix${date.month}月${date.day}日 周${['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7]}';
  }
}

// Add extension for lastOrDefault if not present elsewhere
extension ListUtils<T> on List<T> {
  T? lastOrDefault(T? defaultValue) {
    return isEmpty ? defaultValue : last;
  }
} 