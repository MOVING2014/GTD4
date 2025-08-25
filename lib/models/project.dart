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
  bool needsMonthlyReview;
  DateTime? lastReviewDate;

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
    this.needsMonthlyReview = false,
    this.lastReviewDate,
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
    bool? needsMonthlyReview,
    DateTime? lastReviewDate,
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
      needsMonthlyReview: needsMonthlyReview ?? this.needsMonthlyReview,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
    );
  }

  bool get isCompleted => status == ProjectStatus.completed;
  
  bool get needsReview {
    if (!needsMonthlyReview) return false;
    if (lastReviewDate == null) return true;
    
    final now = DateTime.now();
    // 正确处理跨年的月份计算
    int targetYear = now.year;
    int targetMonth = now.month - 1;
    if (targetMonth <= 0) {
      targetMonth = 12 + targetMonth;  // 如果是1月，则上月是12月
      targetYear = targetYear - 1;      // 年份减1
    }
    final lastMonth = DateTime(targetYear, targetMonth, now.day);
    return lastReviewDate!.isBefore(lastMonth);
  }
  
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
    }
  }
} 