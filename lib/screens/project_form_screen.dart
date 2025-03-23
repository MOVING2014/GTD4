import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

class ProjectFormScreen extends StatefulWidget {
  final Project? project; // 如果为null，则是创建新项目，否则是编辑现有项目

  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late Color _selectedColor;
  late ProjectStatus _status;
  
  bool get _isEditing => widget.project != null;

  // 预定义的颜色选项
  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑项目，填充表单数据
    if (_isEditing) {
      _nameController.text = widget.project!.name;
      _descriptionController.text = widget.project!.description ?? '';
      _selectedColor = widget.project!.color;
      _status = widget.project!.status;
    } else {
      // 创建新项目的默认值
      _selectedColor = Colors.blue;
      _status = ProjectStatus.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      
      if (_isEditing) {
        // 更新现有项目
        final updatedProject = widget.project!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          color: _selectedColor,
          status: _status,
        );
        
        projectProvider.updateProject(updatedProject);
      } else {
        // 创建新项目
        final newProject = Project(
          id: 'p${DateTime.now().millisecondsSinceEpoch}', // 生成唯一ID
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          color: _selectedColor,
          status: _status,
          createdAt: DateTime.now(),
        );
        
        projectProvider.addProject(newProject);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Project' : 'New Project'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Project'),
                    content: const Text('Are you sure you want to delete this project?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<ProjectProvider>(context, listen: false)
                            .deleteProject(widget.project!.id);
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
              // 名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 描述
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // 颜色选择
              const Text('Color:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color 
                              ? Colors.black 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // 状态
              const Text('Status:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<ProjectStatus>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                value: _status,
                items: ProjectStatus.values.map((status) {
                  String label;
                  switch (status) {
                    case ProjectStatus.active:
                      label = 'Active';
                      break;
                    case ProjectStatus.onHold:
                      label = 'On Hold';
                      break;
                    case ProjectStatus.completed:
                      label = 'Completed';
                      break;
                    case ProjectStatus.archived:
                      label = 'Archived';
                      break;
                  }
                  
                  return DropdownMenuItem<ProjectStatus>(
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _saveProject,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(_isEditing ? 'Update Project' : 'Create Project'),
          ),
        ),
      ),
    );
  }
} 