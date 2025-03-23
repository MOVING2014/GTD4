import 'package:flutter/material.dart';

enum ProjectStatus { active, onHold, completed, archived }

class Project {
  final String id;
  final String name;
  String? description;
  Color color;
  ProjectStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  String? parentProjectId;
  int? order;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.color = Colors.blue,
    this.status = ProjectStatus.active,
    required this.createdAt,
    this.completedAt,
    this.parentProjectId,
    this.order,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? parentProjectId,
    int? order,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      parentProjectId: parentProjectId ?? this.parentProjectId,
      order: order ?? this.order,
    );
  }

  bool get isCompleted => status == ProjectStatus.completed;
  
  String get statusText {
    switch (status) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
      default:
        return 'Active';
    }
  }
} 