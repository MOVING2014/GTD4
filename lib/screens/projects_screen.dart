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
        title: const Text('Projects'),
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
              child: Text('No projects yet. Tap + to add a project.'),
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
            project.description ?? 'No description',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressIndicator(context, project),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
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
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
                  
                  switch (value) {
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
                          title: const Text('Delete Project'),
                          content: const Text('Are you sure you want to delete this project?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                projectProvider.deleteProject(project.id);
                                Navigator.of(ctx).pop();
                                setState(() {});
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'toggle_completion',
                    child: Text(project.isCompleted ? 'Mark as Active' : 'Mark as Completed'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'archive',
                    child: Text('Archive Project'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'add_task',
                    child: Text('Add Task to Project'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete Project'),
                  ),
                ],
              ),
            ],
          ),
          children: projectTasks.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No tasks in this project yet.'),
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