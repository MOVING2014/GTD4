import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../screens/task_form_screen.dart';
import '../widgets/add_task_dialog.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskChange;
  
  const TaskListItem({
    super.key,
    required this.task,
    this.onTaskChange,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isNotesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    // 获取项目信息
    Project? project = widget.task.projectId != null 
        ? projectProvider.getProjectById(widget.task.projectId!) 
        : null;
    
    return Slidable(
      // 添加开始动作面板（向右滑动显示）
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              _delayTaskToday(taskProvider);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.today, size: 20),
                SizedBox(height: 2),
                Text('今', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              _delayTaskTomorrow(taskProvider);
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(height: 2),
                Text('明', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              _delayTaskNextWeek(taskProvider);
            },
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.next_week, size: 20),
                SizedBox(height: 2),
                Text('下周', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              _delayTaskNextMonth(taskProvider);
            },
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.calendar_month, size: 20),
                SizedBox(height: 2),
                Text('下月', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              taskProvider.deleteTask(widget.task.id);
              if (widget.onTaskChange != null) {
                widget.onTaskChange!();
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.delete, size: 20),
                SizedBox(height: 2),
                Text('删除', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) async {
              // 使用AddTaskDialog打开任务编辑对话框
              final result = await showAddTaskDialog(
                context,
                task: widget.task,
              );
              
              // 如果编辑成功，调用回调刷新UI
              if (result == true && widget.onTaskChange != null) {
                widget.onTaskChange!();
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.edit, size: 20),
                SizedBox(height: 2),
                Text('编辑', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: widget.task.status == TaskStatus.completed,
                onChanged: (_) {
                  taskProvider.toggleTaskCompletion(widget.task.id);
                  if (widget.onTaskChange != null) {
                    widget.onTaskChange!();
                  }
                },
                activeColor: Colors.transparent,
                checkColor: widget.task.priority == TaskPriority.none 
                    ? Colors.black87 
                    : widget.task.getPriorityColor(),
                fillColor: MaterialStateProperty.resolveWith((states) {
                  // 始终保持透明背景
                  return Colors.transparent;
                }),
                side: MaterialStateBorderSide.resolveWith(
                  (states) => BorderSide(
                    width: 1.5,
                    color: widget.task.priority == TaskPriority.none 
                        ? Colors.black54
                        : widget.task.getPriorityColor(),
                  ),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: TextStyle(
                    decoration: widget.task.status == TaskStatus.completed 
                        ? TextDecoration.lineThrough 
                        : null,
                    color: widget.task.status == TaskStatus.completed 
                        ? Colors.grey 
                        : Colors.black,
                    fontSize: 17.0,
                  ),
                ),
                // 展开备注
                if (_isNotesExpanded && widget.task.notes != null && widget.task.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Text(
                      widget.task.notes!,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                _buildSubtitle(project),
              ],
            ),
            subtitle: null,
            trailing: widget.task.notes != null && widget.task.notes!.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      _isNotesExpanded ? Icons.keyboard_arrow_up : Icons.notes,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNotesExpanded = !_isNotesExpanded;
                      });
                    },
                  )
                : null,
            onTap: null,
            onLongPress: () async {
              // 长按任务使用AddTaskDialog打开编辑对话框
              final result = await showAddTaskDialog(
                context,
                task: widget.task,
              );
              
              // 如果编辑成功，调用回调刷新UI
              if (result == true && widget.onTaskChange != null) {
                widget.onTaskChange!();
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubtitle(Project? project) {
    final List<Widget> rowItems = [];
    
    // 显示到期日期（如果有）
    if (widget.task.dueDate != null) {
      final dateString = widget.task.isDueToday 
          ? '今天' 
          : _formatChineseDate(widget.task.dueDate!);
      
      rowItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: widget.task.isOverdue ? Colors.red.shade300 : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              dateString,
              style: TextStyle(
                color: widget.task.isOverdue ? Colors.red.shade300 : Colors.grey,
                fontWeight: null,
              ),
            ),
          ],
        ),
      );
    }
    
    // 显示项目信息（如果有）
    if (project != null) {
      // 如果已经有日期信息，添加间隔
      if (rowItems.isNotEmpty) {
        rowItems.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('•', style: TextStyle(color: Colors.grey)),
          ),
        );
      }
      
      rowItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_outlined,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              project.name,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    if (rowItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: rowItems,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }
  
  // 将日期格式化为中文格式
  String _formatChineseDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return '今天';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return '明天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
  
  // 将任务延期到今天
  void _delayTaskToday(TaskProvider taskProvider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 创建更新后的任务
    final updatedTask = widget.task.copyWith(
      dueDate: today,
    );
    
    // 更新任务
    taskProvider.updateTask(updatedTask);
    
    // 通知UI更新
    if (widget.onTaskChange != null) {
      widget.onTaskChange!();
    }
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务已设置为今天到期')),
    );
  }
  
  // 将任务延期到明天
  void _delayTaskTomorrow(TaskProvider taskProvider) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    // 创建更新后的任务
    final updatedTask = widget.task.copyWith(
      dueDate: tomorrow,
    );
    
    // 更新任务
    taskProvider.updateTask(updatedTask);
    
    // 通知UI更新
    if (widget.onTaskChange != null) {
      widget.onTaskChange!();
    }
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务已设置为明天到期')),
    );
  }
  
  // 将任务延期到下周
  void _delayTaskNextWeek(TaskProvider taskProvider) {
    final now = DateTime.now();
    final nextWeek = DateTime(now.year, now.month, now.day + 7);
    
    // 创建更新后的任务
    final updatedTask = widget.task.copyWith(
      dueDate: nextWeek,
    );
    
    // 更新任务
    taskProvider.updateTask(updatedTask);
    
    // 通知UI更新
    if (widget.onTaskChange != null) {
      widget.onTaskChange!();
    }
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务已设置为下周到期')),
    );
  }
  
  // 将任务延期到下月
  void _delayTaskNextMonth(TaskProvider taskProvider) {
    final now = DateTime.now();
    // 如果当前是12月，则下个月是下一年的1月
    int nextYear = now.month == 12 ? now.year + 1 : now.year;
    int nextMonth = now.month == 12 ? 1 : now.month + 1;
    // 确保日期有效（例如，如果今天是1月31日，下个月可能没有31日）
    int day = now.day;
    // 获取下个月的天数
    int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    if (day > daysInNextMonth) {
      day = daysInNextMonth;
    }
    
    final nextMonthDate = DateTime(nextYear, nextMonth, day);
    
    // 创建更新后的任务
    final updatedTask = widget.task.copyWith(
      dueDate: nextMonthDate,
    );
    
    // 更新任务
    taskProvider.updateTask(updatedTask);
    
    // 通知UI更新
    if (widget.onTaskChange != null) {
      widget.onTaskChange!();
    }
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务已设置为下月到期')),
    );
  }
} 