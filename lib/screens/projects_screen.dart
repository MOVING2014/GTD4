import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';

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
              // TODO: Implement add project
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
          // TODO: Implement add project
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
      trailing: _buildProgressIndicator(context, project),
      children: [
        _buildProjectTasks(context, project),
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