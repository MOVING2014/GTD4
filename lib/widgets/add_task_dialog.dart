import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? task; // 如果为null，则是创建新任务，否则是编辑现有任务

  const AddTaskDialog({super.key, this.task});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  String? _selectedProjectId;
  
  bool get _isEditing => widget.task != null && widget.task!.title.isNotEmpty;
  bool get _isCreatingWithDefaults => widget.task != null && widget.task!.title.isEmpty;

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑任务，填充表单数据
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _notesController.text = widget.task!.notes ?? '';
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _dueDate = widget.task!.dueDate;
      _selectedProjectId = widget.task!.projectId;
    } 
    // 如果是带有默认值创建任务（例如从日历或项目视图）
    else if (_isCreatingWithDefaults) {
      _priority = TaskPriority.none;
      _status = TaskStatus.notStarted;
      
      // 使用传入的预设值
      if (widget.task!.dueDate != null) {
        _dueDate = widget.task!.dueDate;
      }
      
      _selectedProjectId = widget.task!.projectId;
    }
    // 创建全新任务
    else {
      _priority = TaskPriority.none;
      _status = TaskStatus.notStarted;
      _dueDate = null;
      _selectedProjectId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // 处理截止日期 - 只保留日期部分
      DateTime? dueDateOnly;
      if (_dueDate != null) {
        dueDateOnly = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
        );
      }
      
      String taskId = _isEditing 
          ? widget.task!.id 
          : 't${DateTime.now().millisecondsSinceEpoch}';
      
      // 创建或更新任务
      final task = Task(
        id: taskId,
        title: _titleController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        dueDate: dueDateOnly,
        priority: _priority,
        status: _status,
        createdAt: _isEditing ? widget.task!.createdAt : DateTime.now(),
        completedAt: _status == TaskStatus.completed ? DateTime.now() : null,
        projectId: _selectedProjectId,
        isRecurring: false,
        tags: [],
      );
      
      if (_isEditing) {
        taskProvider.updateTask(task);
      } else {
        taskProvider.addTask(task);
      }
      
      Navigator.of(context).pop(true); // 返回true表示成功保存
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final List<Project> projects = projectProvider.allProjects;
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95, // 增加弹窗宽度
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // 减小行高
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入标题';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                
                const SizedBox(height: 16),
                
                // 备注
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // 减小行高
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),
                
                // 项目选择
                DropdownButtonFormField<String?>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: '项目',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // 减小行高
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('收件箱 (无项目)'),
                    ),
                    ...projects.map((project) {
                      return DropdownMenuItem<String?>(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedProjectId = newValue;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 日期和优先级放在同一行
                Row(
                  children: [
                    // 日期选择器
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_dueDate == null 
                          ? '选择日期' 
                          : '${_dueDate!.year}/${_dueDate!.month}/${_dueDate!.day}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_dueDate != null) 
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                      ),
                    const SizedBox(width: 12),
                    // 优先级选择（下拉式）
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: '优先级',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        ),
                        items: TaskPriority.values.map((priority) {
                          String label;
                          Color color;
                          
                          switch (priority) {
                            case TaskPriority.high:
                              label = '高';
                              color = Colors.red;
                              break;
                            case TaskPriority.medium:
                              label = '中';
                              color = Colors.orange;
                              break;
                            case TaskPriority.low:
                              label = '低';
                              color = Colors.blue;
                              break;
                            case TaskPriority.none:
                            default:
                              label = '无';
                              color = Colors.grey;
                              break;
                          }
                          
                          return DropdownMenuItem<TaskPriority>(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(Icons.flag, color: color, size: 18),
                                const SizedBox(width: 8),
                                Text(label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _priority = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(_isEditing ? '更新' : '创建'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 辅助函数：显示添加任务对话框
Future<bool?> showAddTaskDialog(BuildContext context, {Task? task}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AddTaskDialog(task: task),
  );
} 