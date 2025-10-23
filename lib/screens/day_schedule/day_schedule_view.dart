import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import 'add_task_screen.dart';
import 'task_details_screen.dart';

class DayScheduleView extends StatefulWidget {
  const DayScheduleView({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.scrollToTaskId,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
    required this.onBack,
  });

  final DateTime selectedDate;
  final List<ScheduleTask> tasks;
  final int? scrollToTaskId;
  final ValueChanged<ScheduleTask> onAddTask;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;
  final VoidCallback onBack;

  @override
  State<DayScheduleView> createState() => _DayScheduleViewState();
}

class _DayScheduleViewState extends State<DayScheduleView> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _taskKeys = {};
  late DateTime _now;
  Timer? _ticker;

  static const double _minuteHeight = 1.0;
  static const double _pointTaskHeight = 64;
  static const double _rangeMinHeight = 80;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToTaskId != null) {
        _scrollToTask();
      }
    });
  }

  @override
  void didUpdateWidget(DayScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToTaskId != null && widget.scrollToTaskId != oldWidget.scrollToTaskId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTask());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      final current = DateTime.now();
      if (!mounted) return;
      if (current.minute != _now.minute ||
          current.hour != _now.hour ||
          current.day != _now.day) {
        setState(() {
          _now = current;
        });
      }
    });
  }

  void _scrollToTask() {
    final key = _taskKeys[widget.scrollToTaskId];
    final context = key?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  String? _validateTaskTime(
    ScheduleTask candidate, {
    int? ignoreTaskId,
  }) {
    final candidateStart = minutesFromTime(candidate.startTime);
    final candidateEnd = minutesFromTime(candidate.endTime);
    final isPoint = !candidate.hasDuration;

    for (final task in widget.tasks) {
      if (ignoreTaskId != null && task.id == ignoreTaskId) {
        continue;
      }

      final existingStart = minutesFromTime(task.startTime);
      final existingEnd = minutesFromTime(task.endTime);
      final existingIsPoint = !task.hasDuration;

      if (isPoint && existingIsPoint && existingStart == candidateStart) {
        return 'На ${candidate.startTime} уже запланировано дело «${task.title}». Выберите другое время.';
      }

      if (!isPoint &&
          !existingIsPoint &&
          existingStart == candidateStart &&
          existingEnd == candidateEnd) {
        final label = formatTimeLabel(candidate.startTime, candidate.endTime);
        return 'Промежуток $label уже занят делом «${task.title}». Измените время.';
      }
    }

    return null;
  }

  Future<void> _handleAddTask() async {
    final task = await Navigator.of(context).push<ScheduleTask>(
      PageRouteBuilder<ScheduleTask>(
        pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(
          selectedDate: widget.selectedDate,
          validateTask: (candidate) => _validateTaskTime(candidate),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (task != null) {
      widget.onAddTask(task);
    }
  }

  void _showTaskDetails(ScheduleTask task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailsScreen(
          task: task,
          onUpdateTask: widget.onUpdateTask,
          onDeleteTask: widget.onDeleteTask,
          validateTask: (candidate) =>
              _validateTaskTime(candidate, ignoreTaskId: task.id),
        ),
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final dateFormat = DateFormat('d MMMM', 'ru_RU');
    final weekDayFormat = DateFormat('EEEE', 'ru_RU');
    final day = dateFormat.format(date);
    final weekDay = weekDayFormat.format(date);
    return '$day, $weekDay';
  }

  void _toggleTaskCompletion(ScheduleTask task) {
    widget.onUpdateTask(
      task.copyWith(isCompleted: !task.isCompleted),
    );
  }

  Widget _buildTimeline(List<ScheduleTask> tasks) {
    const totalMinutes = 24 * 60;
    final sortedTasks = [...tasks]
      ..sort((a, b) {
        final startCompare =
            minutesFromTime(a.startTime).compareTo(minutesFromTime(b.startTime));
        if (startCompare != 0) {
          return startCompare;
        }
        return minutesFromTime(a.endTime).compareTo(minutesFromTime(b.endTime));
      });

    final timelineHeight = totalMinutes * _minuteHeight;
    final isToday = widget.selectedDate.year == _now.year &&
        widget.selectedDate.month == _now.month &&
        widget.selectedDate.day == _now.day;
    final currentMinutes =
        (_now.hour * 60 + _now.minute).clamp(0, totalMinutes) as int;
    final indicatorTop =
        (currentMinutes.toDouble() * _minuteHeight).clamp(0.0, timelineHeight - 1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Временная лента',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: timelineHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(
                      width: 64,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFF8FAFF), Color(0xFFF1F5FF)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          for (var hour = 0; hour <= 24; hour++)
                            Positioned(
                              top: hour == 24
                                  ? timelineHeight - 12
                                  : hour * 60 * _minuteHeight - 10,
                              left: 0,
                              right: 0,
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      hour % 3 == 0 ? FontWeight.w700 : FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final timelineWidth = constraints.maxWidth;
                          final stackChildren = <Widget>[
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDFEFF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE0E7FF),
                                  ),
                                ),
                              ),
                            ),
                          ];

                          for (var hour = 0; hour <= 24; hour++) {
                            final top = hour * 60 * _minuteHeight;
                            stackChildren.add(
                              Positioned(
                                top: top,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFCBD5F5)
                                      .withOpacity(hour % 3 == 0 ? 0.55 : 0.25),
                                ),
                              ),
                            );
                          }

                          for (final task in sortedTasks) {
                            final start =
                                minutesFromTime(task.startTime).clamp(0, totalMinutes) as int;
                            final end =
                                minutesFromTime(task.endTime).clamp(0, totalMinutes) as int;
                            final isRange = task.hasDuration;
                            final effectiveEnd = isRange
                                ? end
                                : (start + 30).clamp(start + 1, totalMinutes) as int;
                            final top =
                                (start.toDouble() * _minuteHeight).clamp(0.0, timelineHeight);
                            final durationMinutes =
                                (effectiveEnd - start).clamp(1, totalMinutes) as int;
                            final rawHeight =
                                durationMinutes.toDouble() * _minuteHeight;
                            final availableHeight =
                                (timelineHeight - top).clamp(0.0, timelineHeight);
                            if (availableHeight <= 0) {
                              continue;
                            }
                            double height;
                            if (isRange) {
                              final desired = math.max(rawHeight, _rangeMinHeight);
                              height = math.min(desired, availableHeight);
                            } else {
                              height = math.min(_pointTaskHeight, availableHeight);
                            }
                            final left = isRange ? 0.0 : timelineWidth * 0.35;
                            final right = isRange ? 0.0 : timelineWidth * 0.05;
                            final key = _taskKeys.putIfAbsent(task.id, () => GlobalKey());

                            stackChildren.add(
                              Positioned(
                                key: key,
                                top: top,
                                left: left,
                                right: right,
                                height: height,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: _TimelineTaskCard(
                                    task: task,
                                    onToggleComplete: () =>
                                        _toggleTaskCompletion(task),
                                    onOpenDetails: () => _showTaskDetails(task),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (sortedTasks.isEmpty) {
                            stackChildren.add(
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE0E7FF),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'На этот день ещё нет дел. Добавьте первое, чтобы начать план!',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          if (isToday) {
                            stackChildren.add(
                              _CurrentTimeIndicator(
                                top: indicatorTop,
                                label: formatTimeOfDay(
                                  TimeOfDay(hour: _now.hour, minute: _now.minute),
                                ),
                              ),
                            );
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: stackChildren,
                          );
                        },
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

  @override
  Widget build(BuildContext context) {
    _taskKeys.removeWhere((id, _) => widget.tasks.every((task) => task.id != id));
    final dayLabel = _dayLabel(widget.selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddTask,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Расписание дня',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayLabel,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _handleAddTask,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTimeline(widget.tasks),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTaskCard extends StatelessWidget {
  const _TimelineTaskCard({
    required this.task,
    required this.onToggleComplete,
    required this.onOpenDetails,
  });

  final ScheduleTask task;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = task.isCompleted
        ? const Color(0xFFD1FADF)
        : task.isImportant
            ? const Color(0xFFFDE2E4)
            : Colors.white;
    final timeLabel = formatTimeLabel(task.startTime, task.endTime);
    final comment = task.comment.trim();
    final subTasks = task.subTasks;
    final completedSubTasks = subTasks.where((item) => item.isCompleted).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenDetails,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: backgroundColor == Colors.white
                ? Border.all(color: const Color(0xFFE0E7FF))
                : null,
            boxShadow: backgroundColor == Colors.white
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onToggleComplete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 2),
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: task.isCompleted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              timeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (task.isImportant) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC9D9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Важно',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB42318),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.2,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade500,
                    size: 18,
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (subTasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.checklist,
                      size: 16,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completedSubTasks из ${subTasks.length} подзадач',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentTimeIndicator extends StatelessWidget {
  const _CurrentTimeIndicator({
    required this.top,
    required this.label,
  });

  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 2,
                color: const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
