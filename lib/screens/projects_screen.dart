import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../screens/project_form_screen.dart';
import '../screens/task_form_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // 打开项目创建页面
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProjectFormScreen(),
                ),
              );
              
              // 如果返回true，页面状态已更新（已刷新）
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final projects = projectProvider.activeProjects;
          
          if (projects.isEmpty) {
            return const Center(
              child: Text('暂无项目。点击 + 添加新项目。'),
            );
          }
          
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectItem(context, project);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 打开任务创建页面，不指定项目
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
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildProjectItem(BuildContext context, Project project) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final projectTasks = taskProvider.getTasksByProject(project.id);
        
        return ExpansionTile(
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: project.color,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            project.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            project.description ?? '无描述',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressIndicator(context, project),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
                  
                  switch (value) {
                    case 'edit':
                      // 打开项目编辑页面
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectFormScreen(project: project),
                        ),
                      );
                      
                      // 如果返回true，页面状态已更新
                      if (result == true) {
                        setState(() {});
                      }
                      break;
                    case 'toggle_completion':
                      projectProvider.toggleProjectCompletion(project.id);
                      setState(() {});
                      break;
                    case 'archive':
                      projectProvider.archiveProject(project.id);
                      setState(() {});
                      break;
                    case 'add_task':
                      // 打开任务创建页面，并预设项目
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskFormScreen(
                            task: Task(
                              id: 't${DateTime.now().millisecondsSinceEpoch}',
                              title: '',
                              createdAt: DateTime.now(),
                              projectId: project.id,
                            ),
                          ),
                        ),
                      );
                      
                      // 如果返回true，页面状态已更新
                      if (result == true) {
                        setState(() {});
                      }
                      break;
                    case 'delete':
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('删除项目'),
                          content: const Text('确定要删除此项目吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                projectProvider.deleteProject(project.id);
                                Navigator.of(ctx).pop();
                                setState(() {});
                              },
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('编辑项目'),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle_completion',
                    child: Text(project.isCompleted ? '标记为活动' : '标记为已完成'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'archive',
                    child: Text('归档项目'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'add_task',
                    child: Text('添加任务到项目'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('删除项目'),
                  ),
                ],
              ),
            ],
          ),
          children: projectTasks.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('该项目还没有任务。'),
                  ),
                ]
              : projectTasks.map((task) => TaskListItem(task: task)).toList(),
        );
      },
    );
  }
  
  Widget _buildProgressIndicator(BuildContext context, Project project) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final projectTasks = taskProvider.getTasksByProject(project.id);
        final completedTasksCount = projectTasks.where((task) => 
          task.status == TaskStatus.completed).length;
        
        // 无任务时显示一个空的圆形
        if (projectTasks.isEmpty) {
          return Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '0%',
                style: TextStyle(fontSize: 8),
              ),
            ),
          );
        }
        
        // 计算完成百分比
        final progress = completedTasksCount / projectTasks.length;
        
        return Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                strokeWidth: 4,
              ),
              Center(
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 