import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  
  const TaskListItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              taskProvider.deleteTask(task.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
          SlidableAction(
            onPressed: (context) {
              // TODO: Implement edit task
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
        subtitle: _buildSubtitle(),
        trailing: _buildPriorityIndicator(),
      ),
    );
  }
  
  Widget _buildPriorityIndicator() {
    if (task.priority == TaskPriority.none) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: task.getPriorityColor(),
        shape: BoxShape.circle,
      ),
    );
  }
  
  Widget _buildSubtitle() {
    final List<Widget> elements = [];
    
    // Show due time if available
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
    
    // Show project if available
    if (task.projectId != null) {
      if (elements.isNotEmpty) {
        elements.add(const SizedBox(height: 4));
      }
      
      elements.add(
        const Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 14,
              color: Colors.grey,
            ),
            SizedBox(width: 4),
            // TODO: Get actual project name
            Text('Project'),
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