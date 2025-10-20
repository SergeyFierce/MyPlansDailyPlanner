import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import '../../widgets/time_picker_field.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  final ScheduleTask task;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late ScheduleTask _task;
  late TextEditingController _titleController;
  late TextEditingController _commentController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isTimeRange;
  late List<_EditableSubTask> _subTasks;
  late int _nextSubTaskId;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: widget.task.title);
    _commentController = TextEditingController(text: widget.task.comment);
    _startTime = parseTimeOfDay(widget.task.startTime) ??
        const TimeOfDay(hour: 9, minute: 0);
    _endTime = parseTimeOfDay(widget.task.endTime) ??
        const TimeOfDay(hour: 10, minute: 0);
    _isTimeRange = widget.task.hasDuration;
    if (!_isTimeRange) {
      _endTime = _startTime;
    }

    _subTasks = widget.task.subTasks
        .map(
          (subTask) => _EditableSubTask(
            id: subTask.id,
            controller: TextEditingController(text: subTask.title),
            commentController: TextEditingController(text: subTask.comment),
            isCompleted: subTask.isCompleted,
          ),
        )
        .toList();
    _nextSubTaskId = _subTasks.isEmpty
        ? 0
        : _subTasks.map((entry) => entry.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    for (final entry in _subTasks) {
      entry.controller.dispose();
      entry.commentController.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  void _updateTask(ScheduleTask updatedTask) {
    setState(() {
      _task = updatedTask;
    });
    widget.onUpdateTask(updatedTask);
  }

  void _handleTitleChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (_titleError == null) {
        setState(() {
          _titleError = 'Название не может быть пустым';
        });
      }
      return;
    }

    if (_titleError != null) {
      setState(() {
        _titleError = null;
      });
    }

    if (trimmed != _task.title) {
      _updateTask(_task.copyWith(title: trimmed));
    }
  }

  void _handleCommentChanged(String value) {
    final updated = value.trim();
    if (updated != _task.comment) {
      _updateTask(_task.copyWith(comment: updated));
    }
  }

  void _applyTimeRange(bool value) {
    setState(() {
      _isTimeRange = value;
      if (!value) {
        _endTime = _startTime;
      } else if (!isEndAfterStart(_startTime, _endTime)) {
        _endTime = addMinutes(_startTime, 60);
      }
    });
    _commitTimeChanges();
  }

  void _updateStartTime(TimeOfDay time) {
    setState(() {
      _startTime = time;
      if (!_isTimeRange) {
        _endTime = time;
      } else if (!isEndAfterStart(_startTime, _endTime)) {
        _endTime = addMinutes(time, 60);
      }
    });
    _commitTimeChanges();
  }

  void _updateEndTime(TimeOfDay time) {
    setState(() {
      _endTime = time;
    });
    _commitTimeChanges();
  }

  void _commitTimeChanges() {
    final effectiveEnd = _isTimeRange ? _endTime : _startTime;
    _updateTask(
      _task.copyWith(
        startTime: formatTimeOfDay(_startTime),
        endTime: formatTimeOfDay(effectiveEnd),
      ),
    );
  }

  void _toggleImportant(bool value) {
    if (value != _task.isImportant) {
      _updateTask(_task.copyWith(isImportant: value));
    }
  }

  void _toggleCompleted(bool value) {
    if (value != _task.isCompleted) {
      _updateTask(_task.copyWith(isCompleted: value));
    }
  }

  void _addSubTask() {
    setState(() {
      _subTasks.add(
        _EditableSubTask(
          id: _nextSubTaskId++,
          controller: TextEditingController(),
          commentController: TextEditingController(),
          isCompleted: false,
        ),
      );
    });
  }

  void _removeSubTask(int index) {
    if (index < 0 || index >= _subTasks.length) return;
    setState(() {
      final removed = _subTasks.removeAt(index);
      removed.controller.dispose();
      removed.commentController.dispose();
    });
    _commitSubTasks();
  }

  void _commitSubTasks() {
    final updatedSubTasks = <SubTask>[];
    for (final entry in _subTasks) {
      final title = entry.controller.text.trim();
      if (title.isEmpty) continue;
      updatedSubTasks.add(
        SubTask(
          id: entry.id,
          title: title,
          isCompleted: entry.isCompleted,
          comment: entry.commentController.text.trim(),
        ),
      );
    }
    _updateTask(_task.copyWith(subTasks: updatedSubTasks));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить дело?'),
        content: const Text(
          'Вы уверены, что хотите удалить это дело и все его подзадачи?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDeleteTask(_task.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали дела'),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    onChanged: _handleTitleChanged,
                    decoration: InputDecoration(
                      labelText: 'Название дела',
                      errorText: _titleError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    onChanged: _handleCommentChanged,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий',
                      hintText: 'Добавьте детали или контекст',
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _isTimeRange,
                    onChanged: _applyTimeRange,
                    title: const Text('Планировать промежуток времени'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TimePickerField(
                          label: _isTimeRange ? 'Начало' : 'Время',
                          initialTime: _startTime,
                          onTimeChanged: _updateStartTime,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TimePickerField(
                          label: 'Конец',
                          initialTime: _endTime,
                          enabled: _isTimeRange,
                          onTimeChanged: _updateEndTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _task.isCompleted,
                    onChanged: _toggleCompleted,
                    title: const Text('Отметить как выполненное'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _task.isImportant,
                    onChanged: _toggleImportant,
                    title: const Text('Отметить как важное'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Подзадачи',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (_subTasks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Подзадачи ещё не добавлены',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...List.generate(_subTasks.length, (index) {
                    final entry = _subTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: entry.isCompleted,
                                  onChanged: (value) {
                                    setState(() {
                                      entry.isCompleted = value ?? false;
                                    });
                                    _commitSubTasks();
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: entry.controller,
                                    onChanged: (_) => _commitSubTasks(),
                                    decoration: InputDecoration(
                                      labelText: 'Подзадача ${index + 1}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => _removeSubTask(index),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: entry.commentController,
                              onChanged: (_) => _commitSubTasks(),
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Комментарий',
                                hintText: 'Комментарий к подзадаче',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addSubTask,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить подзадачу'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableSubTask {
  _EditableSubTask({
    required this.id,
    required this.controller,
    required this.commentController,
    required this.isCompleted,
  });

  final int id;
  final TextEditingController controller;
  final TextEditingController commentController;
  bool isCompleted;
}
