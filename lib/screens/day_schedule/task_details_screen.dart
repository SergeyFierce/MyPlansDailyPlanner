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
    required this.validateTask,
  });

  final ScheduleTask task;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;
  final String? Function(ScheduleTask task) validateTask;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late ScheduleTask _originalTask;
  late ScheduleTask _editedTask;
  late TextEditingController _titleController;
  late TextEditingController _commentController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isTimeRange;
  late TaskCategory _category;
  late bool _hasReminder;
  late List<_EditableSubTask> _subTasks;
  late int _nextSubTaskId;
  String? _titleError;
  bool _hasChanges = false;
  bool _showAddSubTaskControls = false;
  bool _isSubTaskSectionVisible = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _commentController = TextEditingController();
    _subTasks = [];
    _loadTask(widget.task);
  }

  @override
  void didUpdateWidget(TaskDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id ||
        !_tasksEqual(widget.task, _originalTask)) {
      setState(() {
        _loadTask(widget.task);
      });
    }
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

  void _loadTask(ScheduleTask task) {
    _originalTask = task;
    _editedTask = task;
    _titleController.text = task.title;
    _commentController.text = task.comment;
    _startTime = timeOfDayFromDateTime(task.startUtc.toLocal());
    _endTime = timeOfDayFromDateTime(task.endUtc.toLocal());
    _isTimeRange = task.hasDuration;
    if (!_isTimeRange) {
      _endTime = _startTime;
    } else if (!isEndAfterStart(_startTime, _endTime)) {
      _endTime = addMinutes(_startTime, 5);
    }
    _category = task.category;
    _hasReminder = task.hasReminder;

    for (final entry in _subTasks) {
      entry.controller.dispose();
      entry.commentController.dispose();
    }
    _subTasks = task.subTasks
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
    _showAddSubTaskControls = _subTasks.isNotEmpty;
    _isSubTaskSectionVisible = _subTasks.isNotEmpty;
    _titleError = null;
    _hasChanges = false;
  }

  InputDecoration _fieldDecoration({
    String? label,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
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

  void _applyTaskUpdate(ScheduleTask updatedTask) {
    _editedTask = updatedTask;
    _hasChanges = !_tasksEqual(_originalTask, _editedTask);
  }

  bool _tasksEqual(ScheduleTask a, ScheduleTask b) {
    if (a.title != b.title ||
        a.comment != b.comment ||
        a.startUtc != b.startUtc ||
        a.endUtc != b.endUtc ||
        a.isImportant != b.isImportant ||
        a.isCompleted != b.isCompleted ||
        a.category != b.category ||
        a.hasReminder != b.hasReminder ||
        a.subTasks.length != b.subTasks.length) {
      return false;
    }
    for (var i = 0; i < a.subTasks.length; i++) {
      final first = a.subTasks[i];
      final second = b.subTasks[i];
      if (first.id != second.id ||
          first.title != second.title ||
          first.comment != second.comment ||
          first.isCompleted != second.isCompleted) {
        return false;
      }
    }
    return true;
  }

  void _handleTitleChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _titleError = 'Название не может быть пустым';
      });
      return;
    }

    if (_titleError != null || trimmed != _editedTask.title) {
      setState(() {
        _titleError = null;
        _applyTaskUpdate(_editedTask.copyWith(title: trimmed));
      });
    }
  }

  void _handleCommentChanged(String value) {
    final updated = value.trim();
    if (updated != _editedTask.comment) {
      setState(() {
        _applyTaskUpdate(_editedTask.copyWith(comment: updated));
      });
    }
  }

  void _showInvalidTimeSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Время окончания должно быть позже времени начала.'),
      ),
    );
  }

  void _syncEditedTaskTimes() {
    final startLocal = combineDateAndTime(
      date: _editedTask.date,
      time: _startTime,
    );
    final endLocal = combineDateAndTime(
      date: _editedTask.date,
      time: _isTimeRange ? _endTime : _startTime,
    );
    _applyTaskUpdate(
      _editedTask.copyWith(
        startUtc: startLocal.toUtc(),
        endUtc: _isTimeRange ? endLocal.toUtc() : startLocal.toUtc(),
      ),
    );
  }

  void _applyTimeRange(bool value) {
    setState(() {
      _isTimeRange = value;
      if (!value) {
        _endTime = _startTime;
      } else if (!isEndAfterStart(_startTime, _endTime)) {
        _endTime = addMinutes(_startTime, 5);
      }
      _syncEditedTaskTimes();
    });
  }

  void _updateStartTime(TimeOfDay time) {
    setState(() {
      _startTime = time;
      if (!_isTimeRange) {
        _endTime = time;
      } else if (!isEndAfterStart(_startTime, _endTime)) {
        _endTime = addMinutes(time, 5);
      }
      _syncEditedTaskTimes();
    });
  }

  void _updateEndTime(TimeOfDay time) {
    if (!isEndAfterStart(_startTime, time)) {
      _showInvalidTimeSnack();
      return;
    }
    setState(() {
      _endTime = time;
      _syncEditedTaskTimes();
    });
  }

  void _toggleImportant(bool value) {
    setState(() {
      _applyTaskUpdate(_editedTask.copyWith(isImportant: value));
    });
  }

  void _toggleCompleted(bool value) {
    setState(() {
      _applyTaskUpdate(_editedTask.copyWith(isCompleted: value));
    });
  }

  void _addSubTask() {
    setState(() {
      _showAddSubTaskControls = true;
      _isSubTaskSectionVisible = true;
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
      _showAddSubTaskControls = _subTasks.isNotEmpty;
      _applyTaskUpdate(_editedTask.copyWith(subTasks: _collectSubTasks()));
    });
  }

  List<SubTask> _collectSubTasks() {
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
    return updatedSubTasks;
  }

  void _commitSubTasks() {
    setState(() {
      _applyTaskUpdate(_editedTask.copyWith(subTasks: _collectSubTasks()));
    });
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
      widget.onDeleteTask(_editedTask.id);
      Navigator.of(context).pop();
    }
  }

  void _saveChanges() {
    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) {
      setState(() {
        _titleError = 'Название не может быть пустым';
      });
      return;
    }

    final updatedTask = _editedTask.copyWith(
      title: trimmedTitle,
      comment: _commentController.text.trim(),
      subTasks: _collectSubTasks(),
    );

    final validationError = widget.validateTask(updatedTask);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    widget.onUpdateTask(updatedTask);
    setState(() {
      _loadTask(updatedTask);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Изменения сохранены')),
    );
  }

  Future<bool> _handleBackNavigation() async {
    if (!_hasChanges) {
      return true;
    }

    final result = await showDialog<_BackAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить изменения?'),
        content: const Text('Вы внесли изменения. Сохранить их перед выходом?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_BackAction.cancel),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_BackAction.discard),
            child: const Text('Не сохранять'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_BackAction.save),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == null || result == _BackAction.cancel) {
      return false;
    }

    if (result == _BackAction.save) {
      _saveChanges();
    }

    return true;
  }

  Future<void> _onBackPressed() async {
    final shouldLeave = await _handleBackNavigation();
    if (shouldLeave && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subTaskCardColor =
        Color.lerp(colorScheme.secondaryContainer, colorScheme.surface, 0.25)!;
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Детали дела'),
          leading: IconButton(
            onPressed: _onBackPressed,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _saveChanges,
                child: const Text('Сохранить'),
              ),
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
                      decoration: _fieldDecoration(
                        label: 'Название дела',
                        errorText: _titleError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      onChanged: _handleCommentChanged,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        label: 'Комментарий',
                        hint: 'Добавьте детали или контекст',
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
                      value: _editedTask.isCompleted,
                      onChanged: _toggleCompleted,
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Отметить как выполненное'),
                          SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 24),
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
                            setState(() {
                              _category = category;
                              _applyTaskUpdate(
                                _editedTask.copyWith(category: category),
                              );
                            });
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
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _editedTask.isImportant,
                      onChanged: _toggleImportant,
                      title: const Text('Отметить как важное'),
                      secondary: Icon(
                        Icons.star_rounded,
                        color:
                            _editedTask.isImportant ? const Color(0xFFFB7185) : Colors.grey,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: _hasReminder,
                      onChanged: (value) {
                        setState(() {
                          _hasReminder = value;
                          _applyTaskUpdate(
                            _editedTask.copyWith(hasReminder: value),
                          );
                        });
                      },
                      title: const Text('Напоминание включено'),
                      secondary: Icon(
                        Icons.notifications_active_rounded,
                        color: _hasReminder ? const Color(0xFF38BDF8) : Colors.grey,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (!_isSubTaskSectionVisible)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSubTaskSectionVisible = true;
                      });
                    },
                    icon: const Icon(Icons.list_alt),
                    label: Text(
                      _subTasks.isEmpty
                          ? 'Показать подзадачи'
                          : 'Показать подзадачи (${_subTasks.length})',
                    ),
                  ),
                ),
              if (_isSubTaskSectionVisible)
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Подзадачи',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (!_showAddSubTaskControls && _subTasks.isEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: _addSubTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить подзадачу'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          IconButton(
                            tooltip: 'Скрыть раздел',
                            onPressed: () {
                              setState(() {
                                _isSubTaskSectionVisible = false;
                              });
                            },
                            icon: const Icon(Icons.expand_less),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_subTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: subTaskCardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Подзадачи ещё не добавлены',
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ...List.generate(_subTasks.length, (index) {
                        final entry = _subTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: subTaskCardColor,
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
                                          _applyTaskUpdate(
                                            _editedTask.copyWith(
                                              subTasks: _collectSubTasks(),
                                            ),
                                          );
                                        });
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
                                        decoration: _fieldDecoration(
                                          label: 'Подзадача ${index + 1}',
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
                                  decoration: _fieldDecoration(
                                    label: 'Комментарий',
                                    hint: 'Комментарий к подзадаче',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_showAddSubTaskControls || _subTasks.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: _addSubTask,
                            icon: const Icon(Icons.add),
                            label: Text(
                              _subTasks.isEmpty
                                  ? 'Добавить подзадачу'
                                  : 'Добавить ещё подзадачу',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BackAction { cancel, discard, save }

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
