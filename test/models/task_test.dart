import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd4_without_clean_achitecture/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task constructor creates valid instance', () {
      final now = DateTime.now();
      
      final task = Task(
        id: '1',
        title: 'Test Task',
        notes: 'Test Notes',
        dueDate: now,
        priority: TaskPriority.medium,
        status: TaskStatus.notStarted,
        createdAt: now,
      );
      
      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.notes, 'Test Notes');
      expect(task.dueDate, now);
      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.notStarted);
      expect(task.createdAt, now);
      expect(task.completedAt, null);
      expect(task.projectId, null);
      expect(task.tags, isEmpty);
      expect(task.isRecurring, false);
      expect(task.recurrenceRule, null);
    });
    
    test('Task copyWith method creates a new instance with updated values', () {
      final now = DateTime.now();
      final later = now.add(const Duration(days: 1));
      
      final task = Task(
        id: '1',
        title: 'Original Title',
        createdAt: now,
      );
      
      final updatedTask = task.copyWith(
        title: 'Updated Title',
        notes: 'Updated Notes',
        dueDate: later,
      );
      
      // 原始Task不应改变
      expect(task.title, 'Original Title');
      expect(task.notes, null);
      
      // 新的Task应该有更新的值
      expect(updatedTask.id, '1'); // 未更新的应保持不变
      expect(updatedTask.title, 'Updated Title');
      expect(updatedTask.notes, 'Updated Notes');
      expect(updatedTask.dueDate, later);
      expect(updatedTask.createdAt, now); // 未更新的应保持不变
    });
    
    test('getPriorityColor returns correct color based on priority', () {
      final mediumPriorityTask = Task(
        id: '1',
        title: 'Medium Priority Task',
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
      );
      
      final noPriorityTask = Task(
        id: '2',
        title: 'No Priority Task',
        priority: TaskPriority.none,
        createdAt: DateTime.now(),
      );
      
      expect(mediumPriorityTask.getPriorityColor(), Colors.orange);
      expect(noPriorityTask.getPriorityColor(), Colors.grey);
    });
    
    test('isOverdue returns correct value based on due date', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      
      final overdueTask = Task(
        id: '1',
        title: 'Overdue Task',
        dueDate: yesterday,
        createdAt: now,
      );
      
      final futureTask = Task(
        id: '2',
        title: 'Future Task',
        dueDate: tomorrow,
        createdAt: now,
      );
      
      final noDateTask = Task(
        id: '3',
        title: 'No Date Task',
        createdAt: now,
      );
      
      final completedOverdueTask = Task(
        id: '4',
        title: 'Completed Overdue Task',
        dueDate: yesterday,
        status: TaskStatus.completed,
        createdAt: now,
      );
      
      expect(overdueTask.isOverdue, true);
      expect(futureTask.isOverdue, false);
      expect(noDateTask.isOverdue, false);
      expect(completedOverdueTask.isOverdue, false);
    });
    
    test('isDueToday returns correct value', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      
      final todayTask = Task(
        id: '1',
        title: 'Today Task',
        dueDate: today,
        createdAt: now,
      );
      
      final tomorrowTask = Task(
        id: '2',
        title: 'Tomorrow Task',
        dueDate: tomorrow,
        createdAt: now,
      );
      
      final noDateTask = Task(
        id: '3',
        title: 'No Date Task',
        createdAt: now,
      );
      
      expect(todayTask.isDueToday, true);
      expect(tomorrowTask.isDueToday, false);
      expect(noDateTask.isDueToday, false);
    });
  });
} 