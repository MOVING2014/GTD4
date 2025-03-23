import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/project.dart';

class MockData {
  // Generate demo projects
  static List<Project> getDemoProjects() {
    return [
      Project(
        id: 'p1',
        name: 'Work',
        description: 'Work-related projects and tasks',
        color: Colors.blue,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Project(
        id: 'p2',
        name: 'Personal',
        description: 'Personal goals and tasks',
        color: Colors.green,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Project(
        id: 'p3',
        name: 'Home',
        description: 'Home improvements and maintenance',
        color: Colors.orange,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Project(
        id: 'p4',
        name: 'Health',
        description: 'Health and fitness goals',
        color: Colors.red,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Project(
        id: 'p5',
        name: 'Learning',
        description: 'Courses and learning goals',
        color: Colors.purple,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  // Generate demo tasks
  static List<Task> getDemoTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      // Today's tasks
      Task(
        id: 't1',
        title: 'Prepare presentation for meeting',
        notes: 'Focus on Q2 results and future projections',
        dueDate: today,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 2)),
        tags: ['meeting', 'presentation'],
      ),
      Task(
        id: 't2',
        title: 'Go for a run',
        dueDate: today,
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        projectId: 'p4',
        createdAt: today.subtract(const Duration(days: 1)),
        completedAt: today,
        isRecurring: true,
        recurrenceRule: 'FREQ=DAILY',
      ),
      
      // Tomorrow's tasks
      Task(
        id: 't3',
        title: 'Review project proposal',
        dueDate: DateTime(today.year, today.month, today.day + 1),
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      
      // This week's tasks
      Task(
        id: 't4',
        title: 'Plan weekend trip',
        notes: 'Check accommodations and transportation options',
        dueDate: DateTime(today.year, today.month, today.day + 3),
        priority: TaskPriority.low,
        status: TaskStatus.notStarted,
        projectId: 'p2',
        createdAt: today.subtract(const Duration(days: 7)),
      ),
      Task(
        id: 't5',
        title: 'Fix kitchen sink',
        dueDate: DateTime(today.year, today.month, today.day + 4),
        priority: TaskPriority.high,
        status: TaskStatus.notStarted,
        projectId: 'p3',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      
      // Next week's tasks
      Task(
        id: 't6',
        title: 'Quarterly budget review',
        dueDate: DateTime(today.year, today.month, today.day + 8),
        priority: TaskPriority.high,
        status: TaskStatus.notStarted,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 10)),
        tags: ['finance', 'quarterly'],
      ),
      
      // Overdue tasks
      Task(
        id: 't7',
        title: 'Call insurance company',
        dueDate: DateTime(today.year, today.month, today.day - 2),
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        projectId: 'p2',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      
      // No due date tasks
      Task(
        id: 't8',
        title: 'Research new programming language',
        notes: 'Look into Rust and its use cases',
        priority: TaskPriority.low,
        status: TaskStatus.notStarted,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 14)),
        tags: ['learning', 'programming'],
      ),
      
      // Tasks for specific projects
      Task(
        id: 't9',
        title: 'Start meditation practice',
        dueDate: DateTime(today.year, today.month, today.day + 2),
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        projectId: 'p4',
        createdAt: today.subtract(const Duration(days: 3)),
        isRecurring: true,
        recurrenceRule: 'FREQ=DAILY',
      ),
      Task(
        id: 't10',
        title: 'Read book on productivity',
        dueDate: DateTime(today.year, today.month, today.day + 10),
        priority: TaskPriority.low,
        status: TaskStatus.inProgress,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 20)),
        tags: ['reading', 'productivity'],
      ),
    ];
  }
} 