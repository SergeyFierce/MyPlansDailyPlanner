import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final ScheduleTask task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  Color? _backgroundColor() {
    if (task.isCompleted) {
      return const Color(0xFFD1FADF);
    }
    if (task.isImportant) {
      return const Color(0xFFFDE2E4);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = _backgroundColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            leading: IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: task.isCompleted
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF4F46E5),
              ),
              onPressed: onToggleComplete,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty) ...[
                  Text(task.description!),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${task.startTime} - ${task.endTime}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isImportant)
                  const Icon(
                    Icons.label_important,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
