import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/settings_button.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('收件箱'),
        actions: [
          // 显示/隐藏已完成任务的过滤器按钮
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return IconButton(
                icon: Icon(
                  taskProvider.showCompletedTasks 
                      ? Icons.check_circle_outline 
                      : Icons.check_circle,
                  color: taskProvider.showCompletedTasks ? Colors.grey : Colors.green,
                ),
                tooltip: taskProvider.showCompletedTasks ? '隐藏已完成任务' : '显示已完成任务',
                onPressed: () {
                  taskProvider.toggleShowCompletedTasks();
                },
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // 使用弹窗添加任务
              final result = await showAddTaskDialog(context);
              
              // 如果返回true，页面状态已更新
              if (result == true) {
                setState(() {});
              }
            },
          ),
          const SettingsButton(),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final inboxTasks = taskProvider.inboxTasks;
          
          if (inboxTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '收件箱为空',
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // 根据日期将任务分组
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final nextWeek = DateTime(now.year, now.month, now.day + 7);
          
          // 逾期任务
          final overdueTasks = <Task>[];
          // 未来7天内的任务
          final nextWeekTasks = <Task>[];
          // 更远的任务
          final futureTasks = <Task>[];
          // 没有日期的任务
          final noDateTasks = <Task>[];
          // 已完成的任务
          final completedTasks = <Task>[];
          
          for (final task in inboxTasks) {
            if (task.status == TaskStatus.completed) {
              completedTasks.add(task);
              continue;
            }
            
            if (task.dueDate == null) {
              noDateTasks.add(task);
              continue;
            }
            
            final dueDate = DateTime(
              task.dueDate!.year, 
              task.dueDate!.month, 
              task.dueDate!.day
            );
            
            if (dueDate.isBefore(today)) {
              overdueTasks.add(task);
            } else if (dueDate.isBefore(nextWeek) || dueDate.isAtSameMomentAs(nextWeek)) {
              nextWeekTasks.add(task);
            } else {
              futureTasks.add(task);
            }
          }
          
          // 在每个分组内按到期日期排序
          overdueTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
          nextWeekTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
          futureTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
          
          // 计算底部填充，确保浮动按钮不会遮挡内容
          // 为浮动按钮和导航栏腾出足够空间
          final bottomPadding = MediaQuery.of(context).padding.bottom + 80; 
          
          // 构建最终的任务列表，包含分组标题和分组内容
          final listItems = <Widget>[];
          
          // 添加逾期任务分组
          if (overdueTasks.isNotEmpty) {
            listItems.add(_buildGroupHeader('逾期任务', Colors.red));
            for (final task in overdueTasks) {
              listItems.add(TaskListItem(
                task: task,
                onTaskChange: () => setState(() {}),
              ));
            }
          }
          
          // 添加未来7天任务分组
          if (nextWeekTasks.isNotEmpty) {
            listItems.add(_buildGroupHeader('未来七天', Colors.orange));
            for (final task in nextWeekTasks) {
              listItems.add(TaskListItem(
                task: task,
                onTaskChange: () => setState(() {}),
              ));
            }
          }
          
          // 添加更远未来任务分组
          if (futureTasks.isNotEmpty) {
            listItems.add(_buildGroupHeader('未来计划', Colors.blue));
            for (final task in futureTasks) {
              listItems.add(TaskListItem(
                task: task,
                onTaskChange: () => setState(() {}),
              ));
            }
          }
          
          // 添加没有日期的任务分组
          if (noDateTasks.isNotEmpty) {
            listItems.add(_buildGroupHeader('未设置日期', Colors.grey));
            for (final task in noDateTasks) {
              listItems.add(TaskListItem(
                task: task,
                onTaskChange: () => setState(() {}),
              ));
            }
          }
          
          // 添加已完成任务分组
          if (completedTasks.isNotEmpty && taskProvider.showCompletedTasks) {
            listItems.add(_buildGroupHeader('已完成', Colors.green));
            // 在已完成分组内按完成日期倒序排序
            completedTasks.sort((a, b) {
              if (a.completedAt == null && b.completedAt != null) return 1;
              if (a.completedAt != null && b.completedAt == null) return -1;
              if (a.completedAt == null && b.completedAt == null) return 0;
              return b.completedAt!.compareTo(a.completedAt!);
            });
            for (final task in completedTasks) {
              listItems.add(TaskListItem(
                task: task,
                onTaskChange: () => setState(() {}),
              ));
            }
          }
          
          return ListView(
            padding: EdgeInsets.only(bottom: bottomPadding),
            children: listItems,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 使用弹窗添加任务
          final result = await showAddTaskDialog(context);
          
          // 如果返回true，页面状态已更新
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildGroupHeader(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
} 