import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../models/project.dart';
import 'mock_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gtd_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        dueDate TEXT,
        reminderDate TEXT,
        priority INTEGER NOT NULL,
        status INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        projectId TEXT,
        tags TEXT,
        isRecurring INTEGER NOT NULL,
        recurrenceRule TEXT
      )
    ''');

    // Create projects table
    await db.execute('''
      CREATE TABLE projects(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        colorValue INTEGER NOT NULL,
        status INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        parentProjectId TEXT,
        orderIndex INTEGER,
        needsMonthlyReview INTEGER NOT NULL,
        lastReviewDate TEXT
      )
    ''');

    // Insert initial demo data
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Insert demo projects
    final demoProjects = MockData.getDemoProjects();
    for (var project in demoProjects) {
      await db.insert('projects', _projectToMap(project));
    }

    // Insert demo tasks
    final demoTasks = MockData.getDemoTasks();
    for (var task in demoTasks) {
      await db.insert('tasks', _taskToMap(task));
    }
  }

  // Task conversion methods
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'notes': task.notes,
      'dueDate': task.dueDate?.toIso8601String(),
      'reminderDate': task.reminderDate?.toIso8601String(),
      'priority': task.priority.index,
      'status': task.status.index,
      'createdAt': task.createdAt.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
      'projectId': task.projectId,
      'tags': task.tags.isNotEmpty ? jsonEncode(task.tags) : '[]',
      'isRecurring': task.isRecurring ? 1 : 0,
      'recurrenceRule': task.recurrenceRule,
    };
  }

  Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      notes: map['notes'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      reminderDate: map['reminderDate'] != null ? DateTime.parse(map['reminderDate']) : null,
      priority: TaskPriority.values[map['priority']],
      status: TaskStatus.values[map['status']],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      projectId: map['projectId'],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : [],
      isRecurring: map['isRecurring'] == 1,
      recurrenceRule: map['recurrenceRule'],
    );
  }

  // Project conversion methods
  Map<String, dynamic> _projectToMap(Project project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'colorValue': project.color.value,
      'status': project.status.index,
      'createdAt': project.createdAt.toIso8601String(),
      'completedAt': project.completedAt?.toIso8601String(),
      'parentProjectId': project.parentProjectId,
      'orderIndex': project.order,
      'needsMonthlyReview': project.needsMonthlyReview ? 1 : 0,
      'lastReviewDate': project.lastReviewDate?.toIso8601String(),
    };
  }

  Project _projectFromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: Color(map['colorValue']),
      status: ProjectStatus.values[map['status']],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      parentProjectId: map['parentProjectId'],
      order: map['orderIndex'],
      needsMonthlyReview: map['needsMonthlyReview'] == 1,
      lastReviewDate: map['lastReviewDate'] != null ? DateTime.parse(map['lastReviewDate']) : null,
    );
  }

  // Task CRUD operations
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => _taskFromMap(maps[i]));
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    
    if (maps.isEmpty) return null;
    return _taskFromMap(maps.first);
  }

  Future<List<Task>> getTasksByProject(String projectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('tasks', where: 'projectId = ?', whereArgs: [projectId]);
    
    return List.generate(maps.length, (i) => _taskFromMap(maps[i]));
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', _taskToMap(task));
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      _taskToMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Project CRUD operations
  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('projects');
    return List.generate(maps.length, (i) => _projectFromMap(maps[i]));
  }

  Future<Project?> getProjectById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('projects', where: 'id = ?', whereArgs: [id]);
    
    if (maps.isEmpty) return null;
    return _projectFromMap(maps.first);
  }

  Future<int> insertProject(Project project) async {
    final db = await database;
    return await db.insert('projects', _projectToMap(project));
  }

  Future<int> updateProject(Project project) async {
    final db = await database;
    return await db.update(
      'projects',
      _projectToMap(project),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(String id) async {
    final db = await database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 