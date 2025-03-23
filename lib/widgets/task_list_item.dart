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
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          activeColor: task.getPriorityColor(),
          onChanged: (_) {
            taskProvider.toggleTaskCompletion(task.id);
            if (onTaskChange != null) {
              onTaskChange!();
            }
          },
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
        trailing: _buildPriorityIndicator(),
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
  
  Widget _buildPriorityIndicator() {
    if (task.priority == TaskPriority.none) {
      return const SizedBox.shrink();
    }
    
    IconData iconData = Icons.flag;
    Color color;
    
    switch (task.priority) {
      case TaskPriority.high:
        color = Colors.red;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        break;
      case TaskPriority.low:
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
        break;
    }
    
    return Icon(iconData, color: color);
  }
  
  Widget _buildSubtitle(Project? project) {
    final List<Widget> elements = [];
    
    // 显示到期时间（如果有）
    if (task.dueDate != null) {
      final timeString = DateFormat.jm().format(task.dueDate!);
      final dateString = task.isDueToday 
          ? 'Today' 
          : DateFormat.MMMd().format(task.dueDate!);
      
      elements.add(
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: task.isOverdue ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              '$dateString at $timeString',
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
      if (elements.isNotEmpty) {
        elements.add(const SizedBox(height: 4));
      }
      
      elements.add(
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 14,
              color: project.color.withOpacity(0.8),
            ),
            const SizedBox(width: 4),
            Text(
              project.name,
              style: TextStyle(
                color: project.color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }
    
    if (elements.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: elements,
    );
  }
} 