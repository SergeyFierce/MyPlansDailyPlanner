import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskListItem extends StatefulWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _expanded = false;
  final DateFormat _timeFormatter = DateFormat.Hm('ru_RU');

  @override
  Widget build(BuildContext context) {
    final Task task = widget.task;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: colorScheme.surface,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => widget.onToggleComplete(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                task.title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration:
                                      task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                            if (task.isImportant)
                              Icon(Icons.flag, color: colorScheme.primary, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_timeFormatter.format(_toDateTime(task.startMinutes))} – ${_timeFormatter.format(_toDateTime(task.endMinutes))}',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  child: Text(
                    task.description.isEmpty ? 'Описание отсутствует' : task.description,
                    style: textTheme.bodyMedium,
                  ),
                ),
                crossFadeState:
                    _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _toDateTime(int minutes) {
    return DateTime(0, 1, 1, minutes ~/ 60, minutes % 60);
  }
}
