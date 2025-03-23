import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low, none }
enum TaskStatus { notStarted, inProgress, completed, waiting, deferred }

class Task {
  final String id;
  final String title;
  String? notes;
  DateTime? dueDate;
  DateTime? reminderDate;
  TaskPriority priority;
  TaskStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  String? projectId;
  List<String> tags;
  bool isRecurring;
  String? recurrenceRule;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.dueDate,
    this.reminderDate,
    this.priority = TaskPriority.none,
    this.status = TaskStatus.notStarted,
    required this.createdAt,
    this.completedAt,
    this.projectId,
    this.tags = const [],
    this.isRecurring = false,
    this.recurrenceRule,
  });

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? dueDate,
    DateTime? reminderDate,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? projectId,
    List<String>? tags,
    bool? isRecurring,
    String? recurrenceRule,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }

  // Helper method to get color based on priority
  Color getPriorityColor() {
    switch (priority) {
      case TaskPriority.medium:
        return Colors.orange;  // 橙色优先级
      case TaskPriority.high:
      case TaskPriority.low:
      case TaskPriority.none:
      default:
        return Colors.grey;    // 灰色优先级
    }
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    return dueDay.isBefore(today);
  }

  // Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && 
           dueDate!.month == now.month && 
           dueDate!.day == now.day;
  }
} 