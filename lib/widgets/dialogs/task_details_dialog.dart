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
  late TextEditingController _commentController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isImportant;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _commentController = TextEditingController(text: widget.task.description ?? '');
    _startTime = parseTimeOfDay(widget.task.startTime) ??
        const TimeOfDay(hour: 9, minute: 0);
    _endTime = parseTimeOfDay(widget.task.endTime) ??
        const TimeOfDay(hour: 10, minute: 0);
    _isImportant = widget.task.isImportant;
    _isCompleted = widget.task.isCompleted;
  }

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

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      startTime: formatTimeOfDay(_startTime),
      endTime: formatTimeOfDay(_endTime),
      isImportant: _isImportant,
      isCompleted: _isCompleted,
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
              SwitchListTile(
                value: _isCompleted,
                onChanged: (value) => setState(() => _isCompleted = value),
                title: const Text('Отметить как выполненное'),
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
