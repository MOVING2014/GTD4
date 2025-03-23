import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../screens/task_form_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
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
              // 打开任务创建页面
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskFormScreen(),
                ),
              );
              
              // 如果返回true，页面状态已更新
              if (result == true) {
                setState(() {});
              }
            },
          ),
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '收件箱为空',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // 计算底部填充，确保浮动按钮不会遮挡内容
          // 为浮动按钮和导航栏腾出足够空间
          final bottomPadding = MediaQuery.of(context).padding.bottom + 80; 
          
          return ListView.builder(
            // 增加足够的底部边距
            padding: EdgeInsets.only(bottom: bottomPadding),
            itemCount: inboxTasks.length,
            itemBuilder: (context, index) {
              final task = inboxTasks[index];
              return TaskListItem(
                task: task,
                onTaskChange: () => setState(() {}),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 打开任务创建页面
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
          
          // 如果返回true，页面状态已更新
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF5D69B3),
        child: const Icon(Icons.add),
      ),
    );
  }
} 