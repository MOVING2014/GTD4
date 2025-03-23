import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../data/mock_data.dart';

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  
  ProjectProvider() {
    // Load mock data initially
    _projects = MockData.getDemoProjects();
  }
  
  // Get all projects
  List<Project> get allProjects => List.unmodifiable(_projects);
  
  // Get active projects
  List<Project> get activeProjects {
    return _projects
        .where((project) => project.status == ProjectStatus.active)
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
    _projects.add(project);
    notifyListeners();
  }
  
  // Update an existing project
  void updateProject(Project updatedProject) {
    final index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
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
} 