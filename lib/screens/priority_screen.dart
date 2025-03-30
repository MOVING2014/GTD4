import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../widgets/settings_button.dart';

class PriorityScreen extends StatefulWidget {
  const PriorityScreen({super.key});

  @override
  State<PriorityScreen> createState() => _PriorityScreenState();
}

class _PriorityScreenState extends State<PriorityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '优先任务',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.orange,
            fontSize: 34.0,
          ),
        ),
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
          const SettingsButton(),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // 获取所有任务并按优先级和日期排序
          final allTasks = taskProvider.allTasks;
          
          // 首先筛选出有优先级的任务(medium优先级的任务，即橙色优先级)
          final prioritizedTasks = allTasks.where((task) => 
            task.priority == TaskPriority.medium
          ).toList();
          
          // 先按完成状态排序，已完成的放在最后，然后按到期日期升序排序（最早的排在前面）
          prioritizedTasks.sort((a, b) {
            // 首先根据完成状态排序
            if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) {
              return 1; // a已完成，b未完成，a排在后面
            } else if (a.status != TaskStatus.completed && b.status == TaskStatus.completed) {
              return -1; // a未完成，b已完成，a排在前面
            }
            
            // 如果完成状态相同，再按到期日期排序
            // 如果a没有到期日期，排在后面
            if (a.dueDate == null && b.dueDate != null) return 1;
            // 如果b没有到期日期，排在后面
            if (a.dueDate != null && b.dueDate == null) return -1;
            // 如果都没有到期日期，保持原顺序
            if (a.dueDate == null && b.dueDate == null) return 0;
            // 如果都有到期日期，按升序排序（最早的日期排在前面）
            return a.dueDate!.compareTo(b.dueDate!);
          });
          
          if (prioritizedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有优先任务',
                    style: TextStyle(
                      color: Colors.grey[600],
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
          
          for (final task in prioritizedTasks) {
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
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
        ),
      ],
    );
  }
} 