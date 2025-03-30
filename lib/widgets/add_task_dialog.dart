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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context), // Use the app's current theme
          child: child!,
        );
      },
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // 简化优先级处理 - 只判断是"无"还是"有"
    bool hasPriority = _priority != TaskPriority.none;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 8,
      backgroundColor: theme.dialogBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95, // 增加弹窗宽度
        padding: const EdgeInsets.all(24.0),
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
                  decoration: InputDecoration(
                    labelText: '标题',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    prefixIcon: Icon(Icons.title, color: colorScheme.primary),
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
                  decoration: InputDecoration(
                    labelText: '备注',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    prefixIcon: Icon(Icons.note, color: colorScheme.primary),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),
                
                // 项目选择
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.library_books, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedProjectId,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
                            hint: Text('选择项目', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('收件箱 (无项目)', style: TextStyle(color: theme.colorScheme.onSurface)),
                              ),
                              ...projects.map((project) {
                                return DropdownMenuItem<String?>(
                                  value: project.id,
                                  child: Text(project.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                                );
                              }),
                            ],
                            onChanged: (newValue) {
                              setState(() {
                                _selectedProjectId = newValue;
                              });
                            },
                            dropdownColor: theme.dialogBackgroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 日期和优先级放在同一行
                Row(
                  children: [
                    // 日期选择器
                    Expanded(
                      flex: 4,  // 增加日期选择器的空间
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, 
                                size: 18, 
                                color: _dueDate != null ? colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5)
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _dueDate == null 
                                    ? '选择日期' 
                                    : '${_dueDate!.year}/${_dueDate!.month}/${_dueDate!.day}',
                                  style: TextStyle(
                                    color: _dueDate != null 
                                        ? theme.colorScheme.onSurface 
                                        : theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_dueDate != null) 
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _dueDate = null;
                                    });
                                  },
                                  child: Icon(Icons.clear, size: 16, 
                                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 极简化的优先级选择 - 只有图标按钮
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          // 切换优先级状态
                          _priority = hasPriority ? TaskPriority.none : TaskPriority.medium;
                        });
                      },
                      child: Container(
                        width: 48,  // 固定宽度
                        height: 48,  // 固定高度
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.flag,
                            color: hasPriority ? Colors.orange : theme.colorScheme.onSurface.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // 按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
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