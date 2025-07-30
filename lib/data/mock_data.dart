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
        needsMonthlyReview: true,  // 需要月度回顾
        lastReviewDate: DateTime.now().subtract(const Duration(days: 35)),  // 上次回顾超过一个月，需要回顾
      ),
      Project(
        id: 'p2',
        name: '个人',
        description: '个人目标和任务',
        color: Colors.green,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        needsMonthlyReview: true,  // 需要月度回顾
        lastReviewDate: DateTime.now().subtract(const Duration(days: 15)),  // 最近回顾过，不需要回顾
      ),
      Project(
        id: 'p3',
        name: '家庭',
        description: '家庭改善和维护',
        color: Colors.orange,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        needsMonthlyReview: true,  // 需要月度回顾
        lastReviewDate: null,  // 从未回顾过，需要回顾
      ),
      Project(
        id: 'p4',
        name: '健康',
        description: '健康和健身目标',
        color: Colors.red,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        needsMonthlyReview: false,  // 不需要月度回顾
      ),
      Project(
        id: 'p5',
        name: '学习',
        description: '课程和学习目标',
        color: Colors.purple,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        needsMonthlyReview: true,  // 需要月度回顾
        lastReviewDate: DateTime.now().subtract(const Duration(days: 45)),  // 很久没回顾了，需要回顾
      ),
      Project(
        id: 'p6',
        name: '阅读',
        description: '阅读计划与书籍记录',
        color: Colors.amber,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        needsMonthlyReview: true,  // 需要月度回顾
        status: ProjectStatus.completed,  // 已完成的项目不需要回顾
        completedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Project(
        id: 'p7',
        name: '财务',
        description: '财务规划和投资',
        color: Colors.teal,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        needsMonthlyReview: true,  // 需要月度回顾
        lastReviewDate: DateTime.now().subtract(const Duration(days: 32)),  // 刚好超过一个月，需要回顾
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
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.inProgress,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 2)),
        tags: ['会议', '演示'],
      ),
      Task(
        id: 't2',
        title: '去跑步',
        dueDate: today,
        priority: TaskPriority.none,    // 灰色优先级
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
        priority: TaskPriority.medium,  // 橙色优先级
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
        priority: TaskPriority.none,    // 灰色优先级
        status: TaskStatus.notStarted,
        projectId: 'p2',
        createdAt: today.subtract(const Duration(days: 7)),
      ),
      Task(
        id: 't5',
        title: '修理厨房水槽',
        dueDate: DateTime(today.year, today.month, today.day + 4),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.notStarted,
        projectId: 'p3',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      
      // Next week's tasks
      Task(
        id: 't6',
        title: '季度预算审核',
        dueDate: DateTime(today.year, today.month, today.day + 8),
        priority: TaskPriority.medium,  // 橙色优先级
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
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.notStarted,
        projectId: 'p2',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      
      // No due date tasks
      Task(
        id: 't8',
        title: '研究新的编程语言',
        notes: '了解Rust及其用例',
        priority: TaskPriority.none,    // 灰色优先级
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
        priority: TaskPriority.medium,  // 橙色优先级
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
        priority: TaskPriority.none,    // 灰色优先级
        status: TaskStatus.inProgress,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 20)),
        tags: ['阅读', '生产力'],
      ),
      
      // 工作项目(p1)的其他任务 - 需要回顾
      Task(
        id: 't11',
        title: '完成客户项目文档',
        notes: '需要包含所有功能规格和实施计划',
        dueDate: DateTime(today.year, today.month, today.day + 15),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.notStarted,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 25)),
        tags: ['文档', '客户'],
      ),
      Task(
        id: 't12',
        title: '员工季度评估',
        dueDate: DateTime(today.year, today.month, today.day + 12),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.notStarted,
        projectId: 'p1',
        createdAt: today.subtract(const Duration(days: 5)),
        tags: ['管理', '评估'],
      ),
      
      // 家庭项目(p3)的其他任务 - 从未回顾
      Task(
        id: 't13',
        title: '检查房屋保险更新',
        dueDate: DateTime(today.year, today.month, today.day + 7),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.notStarted,
        projectId: 'p3',
        createdAt: today.subtract(const Duration(days: 15)),
      ),
      Task(
        id: 't14',
        title: '安排院子维护工作',
        dueDate: DateTime(today.year, today.month, today.day + 3),
        priority: TaskPriority.none,    // 灰色优先级
        status: TaskStatus.inProgress,
        projectId: 'p3',
        createdAt: today.subtract(const Duration(days: 10)),
      ),
      
      // 学习项目(p5)的其他任务 - 很久没回顾
      Task(
        id: 't15',
        title: '完成在线课程第三单元',
        dueDate: DateTime(today.year, today.month, today.day + 5),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.inProgress,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 30)),
        tags: ['课程', '学习'],
      ),
      Task(
        id: 't16',
        title: '为博客写一篇技术文章',
        dueDate: DateTime(today.year, today.month, today.day + 9),
        priority: TaskPriority.none,    // 灰色优先级
        status: TaskStatus.notStarted,
        projectId: 'p5',
        createdAt: today.subtract(const Duration(days: 40)),
        tags: ['写作', '技术'],
      ),
      
      // 财务项目(p7)的任务 - 刚好需要回顾
      Task(
        id: 't17',
        title: '更新个人预算计划',
        dueDate: DateTime(today.year, today.month, today.day + 2),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.notStarted,
        projectId: 'p7',
        createdAt: today.subtract(const Duration(days: 45)),
        tags: ['预算', '规划'],
      ),
      Task(
        id: 't18',
        title: '研究投资选项',
        notes: '考虑股票、债券和ETF',
        dueDate: DateTime(today.year, today.month, today.day + 14),
        priority: TaskPriority.medium,  // 橙色优先级
        status: TaskStatus.inProgress,
        projectId: 'p7',
        createdAt: today.subtract(const Duration(days: 20)),
        tags: ['投资', '研究'],
      ),
      Task(
        id: 't19',
        title: '准备税务文件',
        dueDate: DateTime(today.year, today.month, today.day + 30),
        priority: TaskPriority.none,    // 灰色优先级
        status: TaskStatus.notStarted,
        projectId: 'p7',
        createdAt: today.subtract(const Duration(days: 15)),
      ),
    ];
  }
} 