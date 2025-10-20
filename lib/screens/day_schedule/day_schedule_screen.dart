import 'package:flutter/material.dart';

import '../../models/task.dart';
import 'day_schedule_view.dart';

class DayScheduleScreen extends StatefulWidget {
  const DayScheduleScreen({
    super.key,
    required this.selectedDate,
    required this.initialTasks,
    this.initialScrollToTaskId,
    required this.loadTasks,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  final DateTime selectedDate;
  final List<ScheduleTask> initialTasks;
  final int? initialScrollToTaskId;
  final List<ScheduleTask> Function() loadTasks;
  final ValueChanged<ScheduleTask> onAddTask;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;

  @override
  State<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends State<DayScheduleScreen> {
  late List<ScheduleTask> _tasks;
  int? _scrollToTaskId;

  @override
  void initState() {
    super.initState();
    _tasks = List<ScheduleTask>.from(widget.initialTasks);
    _scrollToTaskId = widget.initialScrollToTaskId;
  }

  void _refreshTasks({int? scrollToTaskId}) {
    setState(() {
      _tasks = widget.loadTasks();
      _scrollToTaskId = scrollToTaskId;
    });
  }

  void _handleAddTask(ScheduleTask task) {
    final existingIds = _tasks.map((existingTask) => existingTask.id).toSet();
    widget.onAddTask(task);
    final updatedTasks = widget.loadTasks();
    int? newScrollId;
    for (final updatedTask in updatedTasks) {
      if (!existingIds.contains(updatedTask.id)) {
        newScrollId = updatedTask.id;
        break;
      }
    }

    setState(() {
      _tasks = updatedTasks;
      _scrollToTaskId = newScrollId;
    });
  }

  void _handleUpdateTask(ScheduleTask task) {
    widget.onUpdateTask(task);
    _refreshTasks(scrollToTaskId: task.id);
  }

  void _handleDeleteTask(int id) {
    widget.onDeleteTask(id);
    _refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DayScheduleView(
        selectedDate: widget.selectedDate,
        tasks: _tasks,
        scrollToTaskId: _scrollToTaskId,
        onAddTask: _handleAddTask,
        onUpdateTask: _handleUpdateTask,
        onDeleteTask: _handleDeleteTask,
        onBack: () => Navigator.of(context).pop(),
      ),
    );
  }
}
