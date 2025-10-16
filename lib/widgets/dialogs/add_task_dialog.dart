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
  final _commentController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isImportant = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime.hour > _endTime.hour ||
        (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время окончания должно быть позже начала.')),
      );
      return;
    }

    final task = ScheduleTask(
      id: 0,
      title: _titleController.text.trim(),
      description: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      startTime: formatTimeOfDay(_startTime),
      endTime: formatTimeOfDay(_endTime),
      isImportant: _isImportant,
      date: widget.selectedDate,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: 'Комментарий'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TimePickerField(
                      label: 'Начало',
                      initialTime: _startTime,
                      onTimeChanged: (time) => setState(() => _startTime = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TimePickerField(
                      label: 'Конец',
                      initialTime: _endTime,
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
