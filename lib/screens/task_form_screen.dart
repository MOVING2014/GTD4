import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../utils/date_utils.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // 如果为null，则是创建新任务，否则是编辑现有任务

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _selectedProjectId;
  bool _isRecurring = false;
  String _recurrenceRule = 'FREQ=DAILY';
  List<String> _tags = [];
  
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑任务，填充表单数据
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _notesController.text = widget.task!.notes ?? '';
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _dueDate = widget.task!.dueDate != null ? 
                 DateTime(widget.task!.dueDate!.year, widget.task!.dueDate!.month, widget.task!.dueDate!.day) : 
                 null;
      _dueTime = widget.task!.dueDate != null ? 
                 TimeOfDay(hour: widget.task!.dueDate!.hour, minute: widget.task!.dueDate!.minute) : 
                 null;
      _selectedProjectId = widget.task!.projectId;
      _isRecurring = widget.task!.isRecurring;
      _recurrenceRule = widget.task!.recurrenceRule ?? 'FREQ=DAILY';
      _tags = List.from(widget.task!.tags);
    } else {
      // 创建新任务的默认值
      _priority = TaskPriority.none;
      _status = TaskStatus.notStarted;
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    
    if (picked != null && picked != _dueTime) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // 合并日期和时间
      DateTime? combinedDateTime;
      if (_dueDate != null) {
        if (_dueTime != null) {
          combinedDateTime = DateTime(
            _dueDate!.year,
            _dueDate!.month,
            _dueDate!.day,
            _dueTime!.hour,
            _dueTime!.minute,
          );
        } else {
          combinedDateTime = _dueDate;
        }
      }
      
      if (_isEditing) {
        // 更新现有任务
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          dueDate: combinedDateTime,
          priority: _priority,
          status: _status,
          projectId: _selectedProjectId,
          isRecurring: _isRecurring,
          recurrenceRule: _isRecurring ? _recurrenceRule : null,
          tags: _tags,
        );
        
        taskProvider.updateTask(updatedTask);
      } else {
        // 创建新任务
        final newTask = Task(
          id: 't${DateTime.now().millisecondsSinceEpoch}', // 生成唯一ID
          title: _titleController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          dueDate: combinedDateTime,
          priority: _priority,
          status: _status,
          createdAt: DateTime.now(),
          projectId: _selectedProjectId,
          isRecurring: _isRecurring,
          recurrenceRule: _isRecurring ? _recurrenceRule : null,
          tags: _tags,
        );
        
        taskProvider.addTask(newTask);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<TaskProvider>(context, listen: false)
                            .deleteTask(widget.task!.id);
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 备注
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // 项目选择
              Consumer<ProjectProvider>(
                builder: (context, projectProvider, child) {
                  final projects = projectProvider.activeProjects;
                  
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedProjectId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No Project'),
                      ),
                      ...projects.map((project) => DropdownMenuItem<String>(
                        value: project.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: project.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(project.name),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProjectId = value;
                      });
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // 优先级
              Row(
                children: [
                  const Text('Priority:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SegmentedButton<TaskPriority>(
                      segments: const [
                        ButtonSegment<TaskPriority>(
                          value: TaskPriority.high,
                          label: Text('High'),
                          icon: Icon(Icons.flag, color: Colors.red),
                        ),
                        ButtonSegment<TaskPriority>(
                          value: TaskPriority.medium,
                          label: Text('Medium'),
                          icon: Icon(Icons.flag, color: Colors.orange),
                        ),
                        ButtonSegment<TaskPriority>(
                          value: TaskPriority.low,
                          label: Text('Low'),
                          icon: Icon(Icons.flag, color: Colors.blue),
                        ),
                        ButtonSegment<TaskPriority>(
                          value: TaskPriority.none,
                          label: Text('None'),
                          icon: Icon(Icons.flag_outlined),
                        ),
                      ],
                      selected: {_priority},
                      onSelectionChanged: (Set<TaskPriority> selected) {
                        setState(() {
                          _priority = selected.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 状态
              Row(
                children: [
                  const Text('Status:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      items: TaskStatus.values.map((status) {
                        String label;
                        switch (status) {
                          case TaskStatus.notStarted:
                            label = 'Not Started';
                            break;
                          case TaskStatus.inProgress:
                            label = 'In Progress';
                            break;
                          case TaskStatus.completed:
                            label = 'Completed';
                            break;
                          case TaskStatus.waiting:
                            label = 'Waiting';
                            break;
                          case TaskStatus.deferred:
                            label = 'Deferred';
                            break;
                        }
                        
                        return DropdownMenuItem<TaskStatus>(
                          value: status,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 日期和时间
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(_dueDate == null 
                          ? 'No date selected' 
                          : AppDateUtils.formatDate(_dueDate!)),
                      onTap: () => _selectDate(context),
                      leading: const Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Due Time'),
                      subtitle: Text(_dueTime == null 
                          ? 'No time selected' 
                          : _dueTime!.format(context)),
                      onTap: () => _selectTime(context),
                      leading: const Icon(Icons.access_time),
                      enabled: _dueDate != null,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 重复选项
              SwitchListTile(
                title: const Text('Recurring Task'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              if (_isRecurring) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Recurrence',
                    border: OutlineInputBorder(),
                  ),
                  value: _recurrenceRule,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'FREQ=DAILY',
                      child: Text('Daily'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'FREQ=WEEKLY',
                      child: Text('Weekly'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'FREQ=MONTHLY',
                      child: Text('Monthly'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurrenceRule = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
              ],
              
              // 标签
              const Text('Tags:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeTag(tag),
                )).toList(),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Add a tag',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (value) {
                        _addTag(value);
                        // 清空输入框
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(_isEditing ? 'Update Task' : 'Create Task'),
          ),
        ),
      ),
    );
  }
} 