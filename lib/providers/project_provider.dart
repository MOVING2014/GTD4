import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/project.dart';
import '../data/database_helper.dart';
import '../screens/projects_screen.dart'; // 导入 ProjectFilter 枚举

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  ProjectProvider() {
    // 从数据库加载项目
    _loadProjects();
  }
  
  // 从数据库加载所有项目
  Future<void> _loadProjects() async {
    _projects = await _dbHelper.getAllProjects();
    // 确保所有项目都有order属性
    _initializeProjectOrders();
    notifyListeners();
  }
  
  // 初始化项目顺序
  void _initializeProjectOrders() {
    // 根据现有顺序，为没有order值的项目设置order
    List<Project> updatedProjects = [];
    
    for (int i = 0; i < _projects.length; i++) {
      if (_projects[i].order == null) {
        updatedProjects.add(_projects[i].copyWith(order: i));
      } else {
        updatedProjects.add(_projects[i]);
      }
    }
    
    _projects = updatedProjects;
    
    // 按order属性排序
    _sortProjectsByOrder();
  }
  
  // 根据order属性对项目列表进行排序
  void _sortProjectsByOrder() {
    _projects.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  }
  
  // 重新排序项目
  Future<void> reorderProjects(int oldIndex, int newIndex, ProjectFilter filter) async {
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
          final updatedProject = currentProject.copyWith(order: currentOrder - 1);
          _projects[index] = updatedProject;
          await _dbHelper.updateProject(updatedProject);
        }
      }
    } else if (oldIndex > newIndex) {
      // 向上移动
      for (int i = oldIndex; i > newIndex; i--) {
        final currentProject = filteredProjects[i - 1];
        final currentOrder = currentProject.order ?? i - 1;
        final index = _projects.indexWhere((p) => p.id == currentProject.id);
        if (index != -1) {
          final updatedProject = currentProject.copyWith(order: currentOrder + 1);
          _projects[index] = updatedProject;
          await _dbHelper.updateProject(updatedProject);
        }
      }
    }
    
    // 更新被拖动项目的顺序
    final projectIndex = _projects.indexWhere((p) => p.id == project.id);
    if (projectIndex != -1) {
      final updatedProject = project.copyWith(order: newIndex);
      _projects[projectIndex] = updatedProject;
      await _dbHelper.updateProject(updatedProject);
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
  Future<void> addProject(Project project) async {
    // 为新项目设置顺序，放在最后
    final int lastOrder = _projects.isEmpty ? 0 : (_projects.map((p) => p.order ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final newProject = project.copyWith(order: lastOrder);
    
    await _dbHelper.insertProject(newProject);
    await _loadProjects(); // 重新加载项目来更新UI
  }
  
  // Update an existing project
  Future<void> updateProject(Project updatedProject) async {
    final index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      // 保留原有的order
      final oldOrder = _projects[index].order;
      final projectToUpdate = updatedProject.copyWith(order: oldOrder);
      
      await _dbHelper.updateProject(projectToUpdate);
      await _loadProjects(); // 重新加载项目来更新UI
    }
  }
  
  // Delete a project
  Future<void> deleteProject(String projectId) async {
    await _dbHelper.deleteProject(projectId);
    await _loadProjects(); // 重新加载项目来更新UI
  }
  
  // Toggle project completion status
  Future<void> toggleProjectCompletion(String projectId) async {
    final project = _projects.firstWhereOrNull((project) => project.id == projectId);
    if (project == null) {
      // Project not found, return early
      return;
    }
    
    final newStatus = project.status == ProjectStatus.completed 
        ? ProjectStatus.active 
        : ProjectStatus.completed;
    
    final updatedProject = project.copyWith(
      status: newStatus,
      completedAt: newStatus == ProjectStatus.completed ? DateTime.now() : null,
    );
    
    await _dbHelper.updateProject(updatedProject);
    await _loadProjects(); // 重新加载项目来更新UI
  }
  
  // Archive a project
  Future<void> archiveProject(String projectId) async {
    final project = _projects.firstWhereOrNull((project) => project.id == projectId);
    if (project == null) {
      // Project not found, return early
      return;
    }
    
    final updatedProject = project.copyWith(status: ProjectStatus.archived);
    
    await _dbHelper.updateProject(updatedProject);
    await _loadProjects(); // 重新加载项目来更新UI
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
  Future<void> setProjectReviewStatus(String projectId, bool needsReview) async {
    final project = _projects.firstWhereOrNull((project) => project.id == projectId);
    if (project == null) {
      // Project not found, return early
      return;
    }
    
    final updatedProject = project.copyWith(needsMonthlyReview: needsReview);
    
    await _dbHelper.updateProject(updatedProject);
    await _loadProjects(); // 重新加载项目来更新UI
  }
  
  // 标记项目已回顾
  Future<void> markProjectAsReviewed(String projectId) async {
    final project = _projects.firstWhereOrNull((project) => project.id == projectId);
    if (project == null) {
      // Project not found, return early
      return;
    }
    
    final updatedProject = project.copyWith(lastReviewDate: DateTime.now());
    
    await _dbHelper.updateProject(updatedProject);
    await _loadProjects(); // 重新加载项目来更新UI
  }
  
  // 刷新项目列表
  Future<void> refreshProjects() async {
    await _loadProjects();
  }
} 