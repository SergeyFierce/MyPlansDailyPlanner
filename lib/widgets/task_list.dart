import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.tasks,
    required this.onTaskClick,
    required this.onUpdateTask,
    required this.onOpenDetails,
  });

  final List<ScheduleTask> tasks;
  final ValueChanged<int> onTaskClick;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<ScheduleTask> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks
          .map(
            (task) => TaskCard(
              key: ValueKey(task.id),
              task: task,
              enableExpansion: false,
              onPrimaryTap: () => onTaskClick(task.id),
              onUpdateTask: onUpdateTask,
              onOpenDetails: () => onOpenDetails(task),
            ),
          )
          .toList(),
    );
  }
}
