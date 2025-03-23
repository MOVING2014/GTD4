import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../data/mock_data.dart';
import '../screens/projects_screen.dart'; // 导入 ProjectFilter 枚举

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  
  ProjectProvider() {
    // Load mock data initially
    _projects = MockData.getDemoProjects();
    // 确保所有项目都有order属性
    _initializeProjectOrders();
  }
  
  // 初始化项目顺序
  void _initializeProjectOrders() {
    // 根据现有顺序，为没有order值的项目设置order
    for (int i = 0; i < _projects.length; i++) {
      if (_projects[i].order == null) {
        _projects[i] = _projects[i].copyWith(order: i);
      }
    }
    
    // 按order属性排序
    _sortProjectsByOrder();
  }
  
  // 根据order属性对项目列表进行排序
  void _sortProjectsByOrder() {
    _projects.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  }
  
  // 重新排序项目
  void reorderProjects(int oldIndex, int newIndex, ProjectFilter filter) {
    List<Project> filteredProjects;
    
    // 根据过滤类型获取对应的项目列表
    switch (filter) {
      case ProjectFilter.active:
        filteredProjects = activeProjects;
        break;
      case ProjectFilter.completed:
        filteredProjects = completedProjects;
        break;
      case ProjectFilter.archived:
        filteredProjects = archivedProjects;
        break;
      case ProjectFilter.all:
        filteredProjects = List.from(_projects);
        break;
    }
    
    // 处理索引变化
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // 获取要移动的项目
    final Project project = filteredProjects[oldIndex];
    
    // 根据新的位置更新所有受影响项目的顺序
    if (oldIndex < newIndex) {
      // 向下移动
      for (int i = oldIndex; i < newIndex; i++) {
        final currentProject = filteredProjects[i + 1];
        final currentOrder = currentProject.order ?? i + 1;
        final index = _projects.indexWhere((p) => p.id == currentProject.id);
        if (index != -1) {
          _projects[index] = currentProject.copyWith(order: currentOrder - 1);
        }
      }
    } else if (oldIndex > newIndex) {
      // 向上移动
      for (int i = oldIndex; i > newIndex; i--) {
        final currentProject = filteredProjects[i - 1];
        final currentOrder = currentProject.order ?? i - 1;
        final index = _projects.indexWhere((p) => p.id == currentProject.id);
        if (index != -1) {
          _projects[index] = currentProject.copyWith(order: currentOrder + 1);
        }
      }
    }
    
    // 更新被拖动项目的顺序
    final projectIndex = _projects.indexWhere((p) => p.id == project.id);
    if (projectIndex != -1) {
      _projects[projectIndex] = project.copyWith(order: newIndex);
    }
    
    // 重新排序项目列表
    _sortProjectsByOrder();
    
    // 通知监听器数据变化
    notifyListeners();
  }
  
  // Get all projects
  List<Project> get allProjects => List.unmodifiable(_projects);
  
  // Get active projects
  List<Project> get activeProjects {
    return _projects
        .where((project) => project.status == ProjectStatus.active)
        .toList();
  }
  
  // Get completed projects
  List<Project> get completedProjects {
    return _projects
        .where((project) => project.status == ProjectStatus.completed)
        .toList();
  }
  
  // Get archived projects
  List<Project> get archivedProjects {
    return _projects
        .where((project) => project.status == ProjectStatus.archived)
        .toList();
  }
  
  // Get a project by id
  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((project) => project.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Add a new project
  void addProject(Project project) {
    // 为新项目设置顺序，放在最后
    final int lastOrder = _projects.isEmpty ? 0 : (_projects.map((p) => p.order ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final newProject = project.copyWith(order: lastOrder);
    _projects.add(newProject);
    notifyListeners();
  }
  
  // Update an existing project
  void updateProject(Project updatedProject) {
    final index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      // 保留原有的order
      final oldOrder = _projects[index].order;
      _projects[index] = updatedProject.copyWith(order: oldOrder);
      notifyListeners();
    }
  }
  
  // Delete a project
  void deleteProject(String projectId) {
    _projects.removeWhere((project) => project.id == projectId);
    notifyListeners();
  }
  
  // Toggle project completion status
  void toggleProjectCompletion(String projectId) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index != -1) {
      final project = _projects[index];
      final newStatus = project.status == ProjectStatus.completed 
          ? ProjectStatus.active 
          : ProjectStatus.completed;
      
      _projects[index] = project.copyWith(
        status: newStatus,
        completedAt: newStatus == ProjectStatus.completed ? DateTime.now() : null,
      );
      
      notifyListeners();
    }
  }
  
  // Archive a project
  void archiveProject(String projectId) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(status: ProjectStatus.archived);
      notifyListeners();
    }
  }
  
  // 获取需要月度回顾的项目
  List<Project> get projectsNeedingReview {
    return _projects
        .where((project) => 
          project.needsMonthlyReview && 
          project.needsReview && 
          project.status == ProjectStatus.active)
        .toList();
  }
  
  // 设置项目回顾属性
  void setProjectReviewStatus(String projectId, bool needsReview) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(needsMonthlyReview: needsReview);
      notifyListeners();
    }
  }
  
  // 标记项目已回顾
  void markProjectAsReviewed(String projectId) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(lastReviewDate: DateTime.now());
      notifyListeners();
    }
  }
} 