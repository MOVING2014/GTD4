import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/project.dart';

class MockData {
  // Generate demo projects
  static List<Project> getDemoProjects() {
    return [
      Project(
        id: 'p1',
        name: '工作',
        description: '工作相关项目和任务',
        color: Colors.blue,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Project(
        id: 'p2',
        name: '个人',
        description: '个人目标和任务',
        color: Colors.green,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Project(
        id: 'p3',
        name: '家庭',
        description: '家庭改善和维护',
        color: Colors.orange,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Project(
        id: 'p4',
        name: '健康',
        description: '健康和健身目标',
        color: Colors.red,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Project(
        id: 'p5',
        name: '学习',
        description: '课程和学习目标',
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
        title: '准备会议演示文稿',
        notes: '关注第二季度业绩和未来预测',
        dueDate: today,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 2)),
        tags: ['会议', '演示'],
      ),
      Task(
        id: 't2',
        title: '去跑步',
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
        title: '审核项目提案',
        dueDate: DateTime(today.year, today.month, today.day + 1),
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      
      // This week's tasks
      Task(
        id: 't4',
        title: '计划周末旅行',
        notes: '检查住宿和交通选项',
        dueDate: DateTime(today.year, today.month, today.day + 3),
        priority: TaskPriority.low,
        status: TaskStatus.notStarted,
        projectId: 'p2',
        createdAt: today.subtract(const Duration(days: 7)),
      ),
      Task(
        id: 't5',
        title: '修理厨房水槽',
        dueDate: DateTime(today.year, today.month, today.day + 4),
        priority: TaskPriority.high,
        status: TaskStatus.notStarted,
        projectId: 'p3',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      
      // Next week's tasks
      Task(
        id: 't6',
        title: '季度预算审核',
        dueDate: DateTime(today.year, today.month, today.day + 8),
        priority: TaskPriority.high,
        status: TaskStatus.notStarted,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 10)),
        tags: ['财务', '季度'],
      ),
      
      // Overdue tasks
      Task(
        id: 't7',
        title: '联系保险公司',
        dueDate: DateTime(today.year, today.month, today.day - 2),
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        projectId: 'p2',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      
      // No due date tasks
      Task(
        id: 't8',
        title: '研究新的编程语言',
        notes: '了解Rust及其用例',
        priority: TaskPriority.low,
        status: TaskStatus.notStarted,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 14)),
        tags: ['学习', '编程'],
      ),
      
      // Tasks for specific projects
      Task(
        id: 't9',
        title: '开始冥想练习',
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
        title: '阅读有关生产力的书籍',
        dueDate: DateTime(today.year, today.month, today.day + 10),
        priority: TaskPriority.low,
        status: TaskStatus.inProgress,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 20)),
        tags: ['阅读', '生产力'],
      ),
    ];
  }
} 