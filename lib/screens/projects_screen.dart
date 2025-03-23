import 'package:flutter/material.dart';
import 'dart:ui'; // 导入 lerpDouble 函数
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';
import '../screens/project_form_screen.dart';
import '../screens/task_form_screen.dart';
import '../widgets/add_task_dialog.dart';

enum ProjectFilter {
  active,
  completed,
  archived,
  all
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  ProjectFilter _currentFilter = ProjectFilter.active;
  
  String _getFilterTitle() {
    switch (_currentFilter) {
      case ProjectFilter.active:
        return '活动项目';
      case ProjectFilter.completed:
        return '已完成项目';
      case ProjectFilter.archived:
        return '已归档项目';
      case ProjectFilter.all:
        return '所有项目';
    }
  }
  
  List<Project> _getFilteredProjects(ProjectProvider provider) {
    switch (_currentFilter) {
      case ProjectFilter.active:
        return provider.activeProjects;
      case ProjectFilter.completed:
        return provider.completedProjects;
      case ProjectFilter.archived:
        return provider.archivedProjects;
      case ProjectFilter.all:
        return provider.allProjects;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getFilterTitle()),
        actions: [
          // 显示/隐藏已完成任务的过滤器按钮
          IconButton(
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
          ),
          PopupMenuButton<ProjectFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (ProjectFilter filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<ProjectFilter>(
                value: ProjectFilter.active,
                child: Text('活动项目'),
              ),
              const PopupMenuItem<ProjectFilter>(
                value: ProjectFilter.completed,
                child: Text('已完成项目'),
              ),
              const PopupMenuItem<ProjectFilter>(
                value: ProjectFilter.archived,
                child: Text('已归档项目'),
              ),
              const PopupMenuItem<ProjectFilter>(
                value: ProjectFilter.all,
                child: Text('所有项目'),
              ),
            ],
          ),
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
          final projects = _getFilteredProjects(projectProvider);
          
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有${_getFilterTitle()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // 使用 ReorderableListView 替换 ListView.builder
          return ReorderableListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectItem(context, project, index);
            },
            onReorder: (oldIndex, newIndex) {
              // 调用 Provider 中的重新排序方法
              projectProvider.reorderProjects(oldIndex, newIndex, _currentFilter);
            },
            // 长按提示
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, animValue)!;
                  return Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    shadowColor: Colors.grey[100],
                    child: child,
                  );
                },
                child: child,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 使用弹窗创建新任务
          final result = await showAddTaskDialog(context);
          
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
  
  Widget _buildProjectItem(BuildContext context, Project project, int index) {
    return Consumer<TaskProvider>(
      key: ValueKey(project.id),
      builder: (context, taskProvider, child) {
        final projectTasks = taskProvider.getTasksByProject(project.id);
        
        return ExpansionTile(
          leading: null,
          title: Text(
            project.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: project.color,
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
                      // 使用弹窗添加任务到项目
                      final result = await showAddTaskDialog(
                        context,
                        task: Task(
                          id: 't${DateTime.now().millisecondsSinceEpoch}',
                          title: '',
                          createdAt: DateTime.now(),
                          projectId: project.id,
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