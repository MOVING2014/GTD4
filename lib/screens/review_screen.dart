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
        title: Text(
          '回顾',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.indigo,
            fontSize: 34.0,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '选择需要回顾的项目:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${projectsToReview.length} 个待回顾',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: projectsToReview.length,
                  itemBuilder: (context, index) {
                    final project = projectsToReview[index];
                    final isSelected = _selectedProject?.id == project.id;
                    return SizedBox(
                      width: 200,
                      child: Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        clipBehavior: Clip.antiAlias,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : Theme.of(context).cardColor,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.library_books, color: project.color),
                            title: Text(
                              project.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              _getLastReviewText(project),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Colors.grey,
                              ),
                            ),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedProject = project;
                              });
                            },
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20, thickness: 1),
              if (_selectedProject != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        onPressed: _selectedProject == null
                            ? null
                            : () {
                                _markProjectAsReviewed(context);
                              },
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        '请先从上方列表选择一个项目进行回顾',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
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
      return '从未回顾';
    }
    
    final now = DateTime.now();
    final difference = now.difference(project.lastReviewDate!);
    
    if (difference.inDays < 1) {
      final reviewTime = project.lastReviewDate!;
      final todayStart = DateTime(now.year, now.month, now.day);
      if (reviewTime.isAfter(todayStart)) {
        return '今天已回顾';
      } else {
        return '昨天回顾';
      }
    } else if (difference.inDays == 1) {
       final reviewTime = project.lastReviewDate!;
       final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
       if (reviewTime.isAfter(yesterdayStart)) {
          return '昨天回顾';
       } else {
         return '2 天前回顾';
       }
    } else if (difference.inDays < 30) {
      return '${difference.inDays} 天前回顾';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months 个月前回顾';
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
    // Cache the current projects list to avoid multiple getter calls
    final currentProjectsToReview = projectProvider.projectsNeedingReview;
    final completedProjectId = _selectedProject!.id;
    final totalOriginalCount = currentProjectsToReview.length;
    
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
            onPressed: () async {
              await projectProvider.markProjectAsReviewed(completedProjectId);
              Navigator.of(ctx).pop();
              
              // Get updated project list once and cache it
              final updatedProjectsToReview = projectProvider.projectsNeedingReview;
              
              setState(() {
                if (updatedProjectsToReview.isNotEmpty) {
                  // Find the next project to select after completing the current one
                  _selectedProject = _getNextProjectToSelect(
                    currentProjectsToReview, 
                    updatedProjectsToReview, 
                    completedProjectId
                  );
                } else {
                  // No more projects to review
                  _selectedProject = null;
                }
              });
              
              // Explicit count - we know exactly 1 project was completed
              const completedCount = 1;
              
              String snackBarMessage;
              if (updatedProjectsToReview.isEmpty) {
                snackBarMessage = '🎉 所有项目回顾已完成！';
              } else {
                snackBarMessage = '项目回顾已完成 ($completedCount/$totalOriginalCount)';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(snackBarMessage),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// Determines the next project to select after completing a review
  Project _getNextProjectToSelect(
    List<Project> originalList,
    List<Project> updatedList,
    String completedProjectId,
  ) {
    if (updatedList.isEmpty) {
      throw StateError('Cannot select next project from empty list');
    }

    // Find the index of the completed project in the original list
    final completedIndex = originalList.indexWhere((p) => p.id == completedProjectId);
    
    if (completedIndex == -1) {
      // Fallback: return the first project if we can't find the completed one
      return updatedList.first;
    }
    
    // If there are projects at or after the completed project's position, select the one at that position
    if (completedIndex < updatedList.length) {
      return updatedList[completedIndex];
    } else {
      // If the completed project was the last one, select the new last project
      return updatedList.last;
    }
  }
  
  void _showLastReviewInfo(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final allProjects = projectProvider.allProjects
        .where((p) => p.needsMonthlyReview && p.status == ProjectStatus.active)
        .toList();
    
    allProjects.sort((a, b) {
      final aNeedsReview = a.needsReview;
      final bNeedsReview = b.needsReview;
      
      if (aNeedsReview && !bNeedsReview) return -1;
      if (!aNeedsReview && bNeedsReview) return 1;
      
      final dateA = a.lastReviewDate ?? DateTime(1970);
      final dateB = b.lastReviewDate ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });

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
                      leading: Icon(Icons.library_books, color: project.color),
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