import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import '../../widgets/time_picker_field.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final List<_SubTaskField> _subTaskFields = [];
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
    _commentController.dispose();
    for (final field in _subTaskFields) {
      field.titleController.dispose();
      field.commentController.dispose();
    }
    super.dispose();
  }

  void _addSubTaskField() {
    setState(() {
      _subTaskFields.add(
        _SubTaskField(
          titleController: TextEditingController(),
          commentController: TextEditingController(),
        ),
      );
    });
  }

  void _removeSubTaskField(int index) {
    if (index < 0 || index >= _subTaskFields.length) return;
    setState(() {
      final removed = _subTaskFields.removeAt(index);
      removed.titleController.dispose();
      removed.commentController.dispose();
    });
  }

  void _pickStartTime(TimeOfDay time) {
    setState(() {
      _startTime = time;
      if (!_isTimeRange) {
        _endTime = time;
      }
    });
  }

  void _pickEndTime(TimeOfDay time) {
    setState(() => _endTime = time);
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
    for (final field in _subTaskFields) {
      final title = field.titleController.text.trim();
      final comment = field.commentController.text.trim();
      if (title.isEmpty && comment.isEmpty) continue;
      subTasks.add(
        SubTask(
          id: DateTime.now().microsecondsSinceEpoch + subTasks.length,
          title: title.isEmpty ? 'Без названия' : title,
          comment: comment,
        ),
      );
    }

    final task = ScheduleTask(
      id: 0,
      title: _titleController.text.trim(),
      comment: _commentController.text.trim(),
      startTime: formatTimeOfDay(_startTime),
      endTime: formatTimeOfDay(effectiveEnd),
      isImportant: _isImportant,
      date: widget.selectedDate,
      subTasks: subTasks,
    );

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  decoration: const InputDecoration(
                    labelText: 'Комментарий',
                    hintText: 'Добавьте детали или контекст',
                  ),
                  maxLines: 3,
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
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _isImportant,
                  onChanged: (value) => setState(() => _isImportant = value),
                  title: const Text('Отметить как важное'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Text(
                  'Подзадачи',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_subTaskFields.isEmpty)
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
                ...List.generate(_subTaskFields.length, (index) {
                  final field = _subTaskFields[index];
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
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: field.titleController,
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
                          const SizedBox(height: 8),
                          TextField(
                            controller: field.commentController,
                            decoration: const InputDecoration(
                              labelText: 'Комментарий',
                              hintText: 'Комментарий к подзадаче',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
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

class _SubTaskField {
  _SubTaskField({
    required this.titleController,
    required this.commentController,
  });

  final TextEditingController titleController;
  final TextEditingController commentController;
}
