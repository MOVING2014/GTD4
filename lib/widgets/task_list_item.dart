import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../screens/task_form_screen.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onTaskChange;
  
  const TaskListItem({
    super.key,
    required this.task,
    this.onTaskChange,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    // 获取项目信息
    Project? project = task.projectId != null 
        ? projectProvider.getProjectById(task.projectId!) 
        : null;
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              taskProvider.deleteTask(task.id);
              if (onTaskChange != null) {
                onTaskChange!();
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
                  builder: (context) => TaskFormScreen(task: task),
                ),
              );
              
              // 如果编辑成功，调用回调刷新UI
              if (result == true && onTaskChange != null) {
                onTaskChange!();
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.status == TaskStatus.completed,
            onChanged: (_) {
              taskProvider.toggleTaskCompletion(task.id);
              if (onTaskChange != null) {
                onTaskChange!();
              }
            },
            activeColor: task.priority == TaskPriority.none 
                ? Colors.black87 
                : task.getPriorityColor(),
            side: BorderSide(
              color: task.priority == TaskPriority.none 
                  ? Colors.black54
                  : task.getPriorityColor(),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed 
                ? TextDecoration.lineThrough 
                : null,
            color: task.status == TaskStatus.completed 
                ? Colors.grey 
                : Colors.black,
          ),
        ),
        subtitle: _buildSubtitle(project),
        onTap: () async {
          // 点击任务打开编辑页面
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskFormScreen(task: task),
            ),
          );
          
          // 如果编辑成功，调用回调刷新UI
          if (result == true && onTaskChange != null) {
            onTaskChange!();
          }
        },
      ),
    );
  }
  
  Widget _buildSubtitle(Project? project) {
    final List<Widget> rowItems = [];
    
    // 显示到期日期（如果有）
    if (task.dueDate != null) {
      final dateString = task.isDueToday 
          ? '今天' 
          : _formatChineseDate(task.dueDate!);
      
      rowItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: task.isOverdue ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              dateString,
              style: TextStyle(
                color: task.isOverdue ? Colors.red : null,
                fontWeight: task.isOverdue ? FontWeight.bold : null,
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