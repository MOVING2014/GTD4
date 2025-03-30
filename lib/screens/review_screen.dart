import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/settings_button.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Project? _selectedProject;

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final projectsToReview = projectProvider.projectsNeedingReview;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('月度回顾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              _showLastReviewInfo(context);
            },
            tooltip: '查看上次回顾日期',
          ),
          const SettingsButton(),
        ],
      ),
      body: projectsToReview.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  '无需回顾的项目',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('所有项目都已按时回顾'),
              ],
            ),
          )
        : Column(
            children: [
              // 项目选择区域
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择需要回顾的项目:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Project>(
                      value: _selectedProject,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintText: '选择项目',
                      ),
                      items: projectsToReview.map((project) {
                        return DropdownMenuItem<Project>(
                          value: project,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder, color: project.color),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  project.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.access_time, size: 16),
                              Text(
                                _getLastReviewText(project),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Project? project) {
                        setState(() {
                          _selectedProject = project;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // 未完成任务列表
              if (_selectedProject != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedProject!.name} 的未完成任务',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_task),
                        onPressed: () {
                          _addNewTask(context);
                        },
                        tooltip: '添加任务',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildTaskList(taskProvider),
                ),
                // 回顾完成按钮
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('标记项目已回顾'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _markProjectAsReviewed(context);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }
  
  Widget _buildTaskList(TaskProvider taskProvider) {
    if (_selectedProject == null) return const SizedBox.shrink();
    
    // 获取该项目的未完成任务
    final tasks = taskProvider.getTasksByProject(_selectedProject!.id)
        .where((task) => task.status != TaskStatus.completed)
        .toList();
    
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text(
              '该项目没有未完成的任务',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return TaskListItem(
          task: tasks[index],
          onTaskChange: () {
            setState(() {});
          },
        );
      },
    );
  }
  
  String _getLastReviewText(Project project) {
    if (project.lastReviewDate == null) {
      return ' 从未回顾';
    }
    
    final now = DateTime.now();
    final difference = now.difference(project.lastReviewDate!);
    
    if (difference.inDays < 1) {
      return ' 今天回顾';
    } else if (difference.inDays < 30) {
      return ' ${difference.inDays}天前回顾';
    } else {
      final months = (difference.inDays / 30).floor();
      return ' $months个月前回顾';
    }
  }
  
  Future<void> _addNewTask(BuildContext context) async {
    if (_selectedProject == null) return;
    
    final result = await showAddTaskDialog(
      context,
      task: Task(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        title: '',
        createdAt: DateTime.now(),
        projectId: _selectedProject!.id,
      ),
    );
    
    if (result == true) {
      setState(() {});
    }
  }
  
  void _markProjectAsReviewed(BuildContext context) {
    if (_selectedProject == null) return;
    
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认回顾完成'),
        content: Text('您确定已完成对"${_selectedProject!.name}"的回顾吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              projectProvider.markProjectAsReviewed(_selectedProject!.id);
              Navigator.of(ctx).pop();
              
              setState(() {
                // 清除选中的项目，以便用户选择下一个
                _selectedProject = null;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('项目回顾已完成'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
  
  void _showLastReviewInfo(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final allProjects = projectProvider.allProjects
        .where((p) => p.needsMonthlyReview && p.status == ProjectStatus.active)
        .toList();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('项目回顾状态'),
        content: SizedBox(
          width: double.maxFinite,
          child: allProjects.isEmpty
              ? const Text('没有设置为需要月度回顾的项目')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allProjects.length,
                  itemBuilder: (context, index) {
                    final project = allProjects[index];
                    return ListTile(
                      leading: Icon(Icons.folder, color: project.color),
                      title: Text(project.name),
                      subtitle: Text(
                        project.lastReviewDate == null
                            ? '从未回顾'
                            : '上次回顾: ${_formatDate(project.lastReviewDate!)}',
                      ),
                      trailing: Icon(
                        project.needsReview
                            ? Icons.warning
                            : Icons.check_circle,
                        color: project.needsReview ? Colors.orange : Colors.green,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
} 