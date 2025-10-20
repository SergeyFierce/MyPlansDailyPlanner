import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import '../../widgets/task_card.dart';
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

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _handleAddTask() async {
    final task = await Navigator.of(context).push<ScheduleTask>(
      PageRouteBuilder<ScheduleTask>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddTaskScreen(selectedDate: widget.selectedDate),
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

  Widget _buildProgressCard(List<ScheduleTask> tasks) {
    final completed = tasks.where((task) => task.isCompleted).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Прогресс дел',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'На этот день дел ещё нет'
                  : '$completed из $total выполнено ($percent%)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<ScheduleTask> tasks) {
    final sortedTasks = [...tasks]
      ..sort((a, b) {
        final startCompare =
            minutesFromTime(a.startTime).compareTo(minutesFromTime(b.startTime));
        if (startCompare != 0) {
          return startCompare;
        }
        return minutesFromTime(a.endTime).compareTo(minutesFromTime(b.endTime));
      });
    final Map<int, List<ScheduleTask>> tasksByMinute = {};
    for (final task in sortedTasks) {
      final minutes = minutesFromTime(task.startTime);
      tasksByMinute.putIfAbsent(minutes, () => []).add(task);
    }

    final baseMarkers = List<int>.generate(25, (index) => index * 60);
    final markers = {
      ...baseMarkers,
      ...tasksByMinute.keys,
    }.toList()
      ..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Временная лента',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const Divider(height: 24),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: const [
                    Icon(Icons.schedule_outlined, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'На этот день дел нет — добавьте первое!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            for (final minutes in markers) ...[
              _TimelineMarker(minutes: minutes),
              ...List.generate(tasksByMinute[minutes]?.length ?? 0, (index) {
                final task = tasksByMinute[minutes]![index];
                final key = _taskKeys.putIfAbsent(task.id, () => GlobalKey());
                return Padding(
                  key: key,
                  padding:
                      const EdgeInsets.only(left: 84, right: 16, top: 8, bottom: 12),
                  child: TaskCard(
                    task: task,
                    onUpdateTask: widget.onUpdateTask,
                    onOpenDetails: () => _showTaskDetails(task),
                  ),
                );
              }),
            ],
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
                    _buildProgressCard(widget.tasks),
                    const SizedBox(height: 16),
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

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final label = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final isFullHour = minute == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                color: isFullHour ? Colors.grey.shade600 : Colors.grey.shade400,
                fontWeight: isFullHour ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(isFullHour ? 0.3 : 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
