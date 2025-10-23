import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import '../../widgets/time_picker_field.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    super.key,
    required this.selectedDate,
    required this.validateTask,
  });

  final DateTime selectedDate;
  final String? Function(ScheduleTask task) validateTask;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isImportant = false;
  bool _isTimeRange = false;
  TaskCategory _category = TaskCategory.work;
  bool _hasReminder = false;

  InputDecoration _fieldDecoration({
    String? label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _categoryLabel(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return 'Работа';
      case TaskCategory.personal:
        return 'Личное';
      case TaskCategory.health:
        return 'Здоровье';
      case TaskCategory.learning:
        return 'Обучение';
    }
  }

  Color _categoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return const Color(0xFF2563EB);
      case TaskCategory.personal:
        return const Color(0xFF7C3AED);
      case TaskCategory.health:
        return const Color(0xFF16A34A);
      case TaskCategory.learning:
        return const Color(0xFFFB923C);
    }
  }

  Color _darken(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _pickStartTime(TimeOfDay time) {
    setState(() {
      _startTime = time;
      if (!_isTimeRange) {
        _endTime = time;
      } else if (!isEndAfterStart(_startTime, _endTime)) {
        _endTime = addMinutes(time, 5);
      }
    });
  }

  void _pickEndTime(TimeOfDay time) {
    if (!isEndAfterStart(_startTime, time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Время окончания должно быть позже времени начала.'),
        ),
      );
      return;
    }
    setState(() => _endTime = time);
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

    final startLocal = combineDateAndTime(
      date: widget.selectedDate,
      time: _startTime,
    );
    final endLocal = combineDateAndTime(
      date: widget.selectedDate,
      time: effectiveEnd,
    );

    final task = ScheduleTask(
      id: 0,
      title: _titleController.text.trim(),
      comment: _commentController.text.trim(),
      startUtc: startLocal.toUtc(),
      endUtc: _isTimeRange ? endLocal.toUtc() : startLocal.toUtc(),
      isImportant: _isImportant,
      date: widget.selectedDate,
      subTasks: const [],
      category: _category,
      hasReminder: _hasReminder,
    );

    final validationError = widget.validateTask(task);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое дело'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Основная информация',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: _fieldDecoration(label: 'Название дела'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Комментарий',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentController,
                      decoration: _fieldDecoration(
                        hint: 'Добавьте детали или контекст',
                      ),
                      maxLines: 3,
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
                      onChanged: (value) {
                        setState(() {
                          _isTimeRange = value;
                          if (!value) {
                            _endTime = _startTime;
                          } else if (!isEndAfterStart(_startTime, _endTime)) {
                            _endTime = addMinutes(_startTime, 5);
                          }
                        });
                      },
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
                            onTimeChanged: _pickStartTime,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TimePickerField(
                            label: 'Конец',
                            initialTime: _endTime,
                            enabled: _isTimeRange,
                            onTimeChanged: _pickEndTime,
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
            Text(
              'Категория',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskCategory.values.map((category) {
                final selected = _category == category;
                final color = _categoryColor(category);
                return ChoiceChip(
                  label: Text(_categoryLabel(category)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _category = category);
                  },
                  selectedColor: color.withOpacity(0.18),
                  labelStyle: TextStyle(
                    color: selected ? _darken(color) : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      Icons.circle,
                      size: 12,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isImportant,
              onChanged: (value) => setState(() => _isImportant = value),
              title: const Text('Отметить как важное'),
              secondary: Icon(
                Icons.star_rounded,
                color: _isImportant ? const Color(0xFFFB7185) : Colors.grey,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _hasReminder,
              onChanged: (value) => setState(() => _hasReminder = value),
              title: const Text('Включить напоминание'),
              secondary: Icon(
                Icons.notifications_active_rounded,
                color: _hasReminder ? const Color(0xFF38BDF8) : Colors.grey,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Подзадачи можно будет добавить и настроить в подробностях задачи.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton(
            onPressed: _submit,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Сохранить'),
            ),
          ),
        ),
      ),
    );
  }
}
