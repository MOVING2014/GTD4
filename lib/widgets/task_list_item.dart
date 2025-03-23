import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../screens/task_form_screen.dart';

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
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              taskProvider.deleteTask(widget.task.id);
              if (widget.onTaskChange != null) {
                widget.onTaskChange!();
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
          SlidableAction(
            onPressed: (context) async {
              // 打开任务编辑页面
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskFormScreen(task: widget.task),
                ),
              );
              
              // 如果编辑成功，调用回调刷新UI
              if (result == true && widget.onTaskChange != null) {
                widget.onTaskChange!();
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
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
                activeColor: widget.task.priority == TaskPriority.none 
                    ? Colors.black87 
                    : widget.task.getPriorityColor(),
                side: BorderSide(
                  color: widget.task.priority == TaskPriority.none 
                      ? Colors.black54
                      : widget.task.getPriorityColor(),
                  width: 1.5,
                ),
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
                    fontWeight: widget.task.status == TaskStatus.completed
                        ? null
                        : FontWeight.bold,
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
              // 长按任务打开编辑页面
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskFormScreen(task: widget.task),
                ),
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
              color: widget.task.isOverdue ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              dateString,
              style: TextStyle(
                color: widget.task.isOverdue ? Colors.red : null,
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
} 