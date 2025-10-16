import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.tasks,
    required this.onTaskClick,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  final List<ScheduleTask> tasks;
  final ValueChanged<int> onTaskClick;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks
          .map(
            (task) => TaskCard(
              key: ValueKey(task.id),
              task: task,
              onTap: () => onTaskClick(task.id),
              onToggleComplete: () =>
                  onUpdateTask(task.copyWith(isCompleted: !task.isCompleted)),
              onDelete: () => onDeleteTask(task.id),
            ),
          )
          .toList(),
    );
  }
}
