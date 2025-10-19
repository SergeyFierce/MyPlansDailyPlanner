import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import '../time_picker_field.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({
    super.key,
    required this.selectedDate,
    required this.onAddTask,
  });

  final DateTime selectedDate;
  final ValueChanged<ScheduleTask> onAddTask;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<TextEditingController> _subTaskControllers = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isImportant = false;
  bool _isTimeRange = false;

  @override
  void initState() {
    super.initState();
    _addSubTaskField();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _subTaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubTaskField() {
    setState(() {
      _subTaskControllers.add(TextEditingController());
    });
  }

  void _removeSubTaskField(int index) {
    if (index < 0 || index >= _subTaskControllers.length) return;
    setState(() {
      final controller = _subTaskControllers.removeAt(index);
      controller.dispose();
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

    final subTasks = <SubTask>[];
    for (final controller in _subTaskControllers) {
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      subTasks.add(
        SubTask(
          id: DateTime.now().microsecondsSinceEpoch + subTasks.length,
          title: text,
        ),
      );
    }

    final task = ScheduleTask(
      id: 0,
      title: _titleController.text.trim(),
      startTime: formatTimeOfDay(_startTime),
      endTime: formatTimeOfDay(effectiveEnd),
      isImportant: _isImportant,
      date: widget.selectedDate,
      subTasks: subTasks,
    );

    widget.onAddTask(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить дело'),
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
              ...List.generate(_subTaskControllers.length, (index) {
                final controller = _subTaskControllers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Подзадача ${index + 1}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeSubTaskField(index),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addSubTaskField,
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
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
