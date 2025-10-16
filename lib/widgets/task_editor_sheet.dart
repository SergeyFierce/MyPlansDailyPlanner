import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    super.key,
    required this.initialDate,
    this.task,
  });

  final DateTime initialDate;
  final Task? task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isImportant;
  late bool _isCompleted;
  final DateFormat _dateFormatter = DateFormat('d MMMM y, EEEE', 'ru_RU');

  @override
  void initState() {
    super.initState();
    final Task? task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _selectedDate = task?.date ?? widget.initialDate;
    _startTime = task?.startTimeOfDay ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = task?.endTimeOfDay ?? const TimeOfDay(hour: 10, minute: 0);
    _isImportant = task?.isImportant ?? false;
    _isCompleted = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.task == null ? 'Новая задача' : 'Редактирование задачи',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Заголовок',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.calendar_today,
                        label: _dateFormatter.format(_selectedDate),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.flag,
                        label: _isImportant ? 'Важно' : 'Обычная',
                        onTap: () => setState(() => _isImportant = !_isImportant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.play_arrow,
                        label: 'Начало ${_formatTime(_startTime)}',
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.stop,
                        label: 'Конец ${_formatTime(_endTime)}',
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                if (widget.task != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _isCompleted,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) {
                      setState(() => _isCompleted = value);
                    },
                    title: const Text('Завершено'),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay initial = isStart ? _startTime : _endTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Время начала' : 'Время окончания',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_compareTime(_startTime, _endTime) >= 0) {
            _endTime = TimeOfDay(hour: (_startTime.hour + 1).clamp(0, 23), minute: _startTime.minute);
          }
        } else {
          _endTime = picked;
          if (_compareTime(_startTime, _endTime) >= 0) {
            _startTime = TimeOfDay(hour: (_endTime.hour - 1).clamp(0, 23), minute: _endTime.minute);
          }
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final int start = Task.minutesFromTimeOfDay(_startTime);
    final int end = Task.minutesFromTimeOfDay(_endTime);
    if (start >= end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время окончания должно быть позже времени начала.')),
      );
      return;
    }
    final Task result = widget.task == null
        ? Task.create(
            date: _selectedDate,
            title: _titleController.text.trim(),
            startMinutes: start,
            endMinutes: end,
            description: _descriptionController.text.trim(),
            isImportant: _isImportant,
          )
        : widget.task!.copyWith(
            date: _selectedDate,
            title: _titleController.text.trim(),
            startMinutes: start,
            endMinutes: end,
            description: _descriptionController.text.trim(),
            isImportant: _isImportant,
            isCompleted: _isCompleted,
          );
    Navigator.of(context).pop(result);
  }

  String _formatTime(TimeOfDay time) {
    final DateTime dateTime = DateTime(0, 0, 0, time.hour, time.minute);
    return DateFormat.Hm('ru_RU').format(dateTime);
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) {
    return (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
