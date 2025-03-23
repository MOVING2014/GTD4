import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_list_item.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda),
            onPressed: () {
              setState(() {
                if (_calendarFormat == CalendarFormat.month) {
                  _calendarFormat = CalendarFormat.week;
                } else {
                  _calendarFormat = CalendarFormat.month;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add task
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar widget
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Tasks for selected day
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    DateFormat.yMMMMd().format(_selectedDay),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                
                // Overdue tasks (if viewing today)
                if (isSameDay(_selectedDay, DateTime.now()))
                  _buildTaskSection(
                    context, 
                    'Overdue', 
                    Colors.red, 
                    (provider) => provider.overdueTasks,
                  ),
                
                // Tasks for selected day
                _buildTaskSection(
                  context,
                  'Tasks',
                  Colors.blue,
                  (provider) => provider.getTasksForDate(_selectedDay),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add task
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildTaskSection(
    BuildContext context,
    String title,
    Color color,
    List<Task> Function(TaskProvider) tasksSelector,
  ) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = tasksSelector(taskProvider);
        
        if (tasks.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$title (${tasks.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskListItem(task: tasks[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 