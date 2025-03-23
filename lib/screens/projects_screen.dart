import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../screens/project_form_screen.dart';
import '../screens/task_form_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 打开项目创建页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProjectFormScreen(),
                ),
              );
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
        onPressed: () {
          // 打开任务创建页面，不指定项目
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildProjectItem(BuildContext context, Project project) {
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
            onPressed: () {
              // 打开项目编辑页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectFormScreen(project: project),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
              
              switch (value) {
                case 'toggle_completion':
                  projectProvider.toggleProjectCompletion(project.id);
                  break;
                case 'archive':
                  projectProvider.archiveProject(project.id);
                  break;
                case 'add_task':
                  // 打开任务创建页面，并预设项目
                  Navigator.push(
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
      children: [
        _buildProjectTasks(context, project),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton.icon(
            onPressed: () {
              // 打开任务创建页面，并预设项目
              Navigator.push(
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
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Task to Project'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicator(BuildContext context, Project project) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.getTasksByProject(project.id);
        if (tasks.isEmpty) return const SizedBox.shrink();
        
        final completedTasks = tasks.where((task) => 
          task.status == TaskStatus.completed).length;
        final totalTasks = tasks.length;
        final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
        
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                strokeWidth: 5,
              ),
              Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProjectTasks(BuildContext context, Project project) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.getTasksByProject(project.id);
        
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No tasks in this project yet'),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskListItem(task: tasks[index]);
          },
        );
      },
    );
  }
} 