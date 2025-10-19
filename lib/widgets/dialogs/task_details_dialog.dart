import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import '../time_picker_field.dart';

class TaskDetailsDialog extends StatefulWidget {
  const TaskDetailsDialog({
    super.key,
    required this.task,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  final ScheduleTask task;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isImportant;
  late bool _isCompleted;
  late bool _isTimeRange;
  late List<_EditableSubTask> _subTasks;

  int _nextSubTaskId = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _startTime = parseTimeOfDay(widget.task.startTime) ??
        const TimeOfDay(hour: 9, minute: 0);
    _endTime = parseTimeOfDay(widget.task.endTime) ??
        const TimeOfDay(hour: 10, minute: 0);
    _isImportant = widget.task.isImportant;
    _isCompleted = widget.task.isCompleted;
    _isTimeRange = widget.task.hasDuration;
    _subTasks = widget.task.subTasks
        .map(
          (subTask) => _EditableSubTask(
            id: subTask.id,
            controller: TextEditingController(text: subTask.title),
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
    for (final entry in _subTasks) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  void _addSubTask() {
    setState(() {
      _subTasks.add(
        _EditableSubTask(
          id: _nextSubTaskId++,
          controller: TextEditingController(),
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
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final effectiveEnd = _isTimeRange ? _endTime : _startTime;

    if (_isTimeRange && !isEndAfterStart(_startTime, _endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время окончания должно быть позже начала.')),
      );
      return;
    }

    final updatedSubTasks = <SubTask>[];
    for (final entry in _subTasks) {
      final title = entry.controller.text.trim();
      if (title.isEmpty) continue;
      updatedSubTasks.add(
        SubTask(
          id: entry.id,
          title: title,
          isCompleted: entry.isCompleted,
        ),
      );
    }

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      startTime: formatTimeOfDay(_startTime),
      endTime: formatTimeOfDay(effectiveEnd),
      isImportant: _isImportant,
      isCompleted: _isCompleted,
      subTasks: updatedSubTasks,
    );

    widget.onUpdateTask(updatedTask);
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.onDeleteTask(widget.task.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактирование дела'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название дела'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isTimeRange,
                onChanged: (value) {
                  setState(() {
                    _isTimeRange = value;
                    if (!value) {
                      _endTime = _startTime;
                    } else if (!isEndAfterStart(_startTime, _endTime)) {
                      _endTime = addMinutes(_startTime, 60);
                    }
                  });
                },
                title: const Text('Планировать промежуток времени'),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TimePickerField(
                      label: _isTimeRange ? 'Начало' : 'Время',
                      initialTime: _startTime,
                      onTimeChanged: (time) => setState(() {
                        _startTime = time;
                        if (!_isTimeRange) {
                          _endTime = time;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TimePickerField(
                      label: 'Конец',
                      initialTime: _endTime,
                      enabled: _isTimeRange,
                      onTimeChanged: (time) => setState(() => _endTime = time),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isImportant,
                onChanged: (value) => setState(() => _isImportant = value),
                title: const Text('Отметить как важное'),
              ),
              SwitchListTile(
                value: _isCompleted,
                onChanged: (value) => setState(() => _isCompleted = value),
                title: const Text('Отметить как выполненное'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Подзадачи',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              if (_subTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Добавьте первую подзадачу',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...List.generate(_subTasks.length, (index) {
                final entry = _subTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: entry.isCompleted,
                        onChanged: (value) => setState(() {
                          entry.isCompleted = value ?? false;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: TextField(
                          controller: entry.controller,
                          decoration: InputDecoration(
                            labelText: 'Подзадача ${index + 1}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeSubTask(index),
                      ),
                    ],
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Удалить'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _EditableSubTask {
  _EditableSubTask({
    required this.id,
    required this.controller,
    required this.isCompleted,
  });

  final int id;
  final TextEditingController controller;
  bool isCompleted;
}
