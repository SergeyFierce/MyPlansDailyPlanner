import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/task.dart';
import '../../utils/time_utils.dart';
import 'add_task_screen.dart';
import 'logic/day_schedule_controller.dart';
import 'models/day_schedule_models.dart';
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

class _DayScheduleViewState extends State<DayScheduleView>
    with WidgetsBindingObserver {
  late final DayScheduleController _controller;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _taskKeys = {};
  final DateFormat _dateFormatter = DateFormat('d MMMM, EEEE', 'ru_RU');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  int? _pendingScrollTaskId;
  double _previousProgress = 0;
  double _currentProgress = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DayScheduleController(
      selectedDate: widget.selectedDate,
      initialTasks: widget.tasks,
    );
    _previousProgress = _controller.state.progress.completionRate;
    _currentProgress = _previousProgress;
    _pendingScrollTaskId = widget.scrollToTaskId;
    _controller.addListener(_handleControllerChanged);
    scheduleMicrotask(() => _controller.initialize());
  }

  @override
  void didUpdateWidget(DayScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.tasks, oldWidget.tasks)) {
      _controller.updateTasks(widget.tasks);
    }
    if (widget.scrollToTaskId != oldWidget.scrollToTaskId &&
        widget.scrollToTaskId != null) {
      _pendingScrollTaskId = widget.scrollToTaskId;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshEnvironment();
    }
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final newValue = _controller.state.progress.completionRate;
    setState(() {
      _previousProgress = _currentProgress;
      _currentProgress = newValue;
      _initialized = true;
    });
  }

  void _maybeScrollToPending() {
    if (_pendingScrollTaskId == null) return;
    final key = _taskKeys[_pendingScrollTaskId];
    final context = key?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
      _pendingScrollTaskId = null;
    }
  }

  bool _taskExistsInState(int id, DayScheduleState state) {
    return state.segments.any(
      (segment) => segment.tasks.any((item) => item.task.id == id),
    );
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
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );

    if (task != null) {
      widget.onAddTask(task);
    }
  }

  void _openTaskDetails(ScheduleTask task) {
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

  String? _validateTaskTime(
    ScheduleTask candidate, {
    int? ignoreTaskId,
  }) {
    final location = _controller.location;
    final candidateStart = tz.TZDateTime.from(candidate.startUtc, location);
    final candidateEnd = tz.TZDateTime.from(candidate.endUtc, location);
    final candidateIsPoint = !candidate.hasDuration;

    for (final task in widget.tasks) {
      if (ignoreTaskId != null && task.id == ignoreTaskId) {
        continue;
      }
      final existingStart = tz.TZDateTime.from(task.startUtc, location);
      final existingEnd = tz.TZDateTime.from(task.endUtc, location);
      final existingIsPoint = !task.hasDuration;

      final sameDay = existingStart.year == candidateStart.year &&
          existingStart.month == candidateStart.month &&
          existingStart.day == candidateStart.day;
      if (!sameDay) continue;

      if (candidateIsPoint && existingIsPoint && existingStart == candidateStart) {
        return 'На ${_timeFormatter.format(candidateStart)} уже запланировано дело «${task.title}». Выберите другое время.';
      }

      if (!candidateIsPoint && !existingIsPoint) {
        final sameStart = existingStart == candidateStart;
        final sameEnd = existingEnd == candidateEnd;
        if (sameStart && sameEnd) {
          final label = formatTimeRange(candidateStart, candidateEnd);
          return 'Промежуток $label уже занят делом «${task.title}». Измените время.';
        }
      }
    }

    return null;
  }

  void _toggleTaskCompletion(ScheduleTask task) {
    widget.onUpdateTask(
      task.copyWith(isCompleted: !task.isCompleted),
    );
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

  Color _categorySurface(TaskCategory category) {
    final base = _categoryColor(category);
    return base.withOpacity(0.12);
  }

  String _segmentRangeLabel(DaySegment segment) {
    final start = _timeFormatter.format(segment.start);
    final end = _timeFormatter.format(segment.end);
    return '$start – $end';
  }

  Widget _buildHeader(DayScheduleState state) {
    final nowLabel = _timeFormatter.format(state.now);
    final dateLabel = _dateFormatter.format(widget.selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Назад',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Расписание дня',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      nowLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleAddTask,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Добавить',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required String message,
    Color? background,
    Color? foreground,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground ?? const Color(0xFF1D4ED8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground ?? const Color(0xFF1E3A8A),
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(DayScheduleState state) {
    final percent = (_currentProgress * 100).clamp(0, 100);
    final total = state.progress.total;
    final completed = state.progress.completed;
    final important = state.progress.important;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Прогресс дня',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _previousProgress,
                      end: _currentProgress,
                    ),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Text(
                        '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F46E5),
                            ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: _previousProgress,
                    end: _currentProgress,
                  ),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      minHeight: 10,
                      value: value.clamp(0, 1),
                      backgroundColor: const Color(0xFFE0E7FF),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildProgressMetric('Всего', '$total'),
                  const SizedBox(width: 16),
                  _buildProgressMetric('Завершено', '$completed'),
                  const SizedBox(width: 16),
                  _buildProgressMetric('Важных', '$important'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationBanner(DayScheduleState state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      child: state.celebrationUnlocked
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 360),
                scale: state.celebrationUnlocked ? 1 : 0.85,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0E7FF), Color(0xFFF5F3FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Отличная работа! Все задачи выполнены, можно посвятить время себе.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCurrentTaskCard(DayScheduleState state) {
    final currentTask = state.currentTask;
    if (currentTask == null) {
      return const SizedBox.shrink();
    }

    final accent = _categoryColor(currentTask.category);
    final timeLabel = formatTimeRange(currentTask.start, currentTask.end);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Hero(
        tag: 'task_${currentTask.task.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.18), accent.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Сейчас',
                        style: TextStyle(
                          color: accent.darken(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Icon(Icons.timelapse, color: accent.darken()),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentTask.task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
                if (currentTask.task.comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    currentTask.task.comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade800,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => _openTaskDetails(currentTask.task),
                    child: const Text('Подробнее'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegments(DayScheduleState state) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          for (final segment in state.segments)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSegmentCard(segment, state),
            ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(DaySegment segment, DayScheduleState state) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  segment.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        segment.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _segmentRangeLabel(segment),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${segment.tasks.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: segment.isEmpty
                  ? Container(
                      key: ValueKey('${segment.type}_empty'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inbox_outlined, color: Colors.grey.shade500),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Здесь пока пусто — самое время добавить задачу.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: ValueKey('${segment.type}_tasks'),
                      children: [
                        for (final item in segment.tasks)
                          _buildTaskTile(
                            item,
                            segment,
                            state,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(
    SegmentedTask item,
    DaySegment segment,
    DayScheduleState state,
  ) {
    final task = item.task;
    final accent = _categoryColor(task.category);
    final background = _categorySurface(task.category);
    final isPast = item.end.isBefore(state.now);
    final key = _taskKeys.putIfAbsent(task.id, () => GlobalKey());
    final timeLabel = formatTimeRange(item.start, item.end);

    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isCurrent ? accent.withOpacity(0.6) : background,
          width: item.isCurrent ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(item.isCurrent ? 0.1 : 0.05),
            blurRadius: item.isCurrent ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleTaskCompletion(task),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    activeColor: accent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _categoryLabel(task.category),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: accent.darken(),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            if (item.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'В процессе',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: accent.darken(),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: task.isCompleted
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade900,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                        ),
                        if (task.comment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.comment,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                  height: 1.3,
                                ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (task.isImportant)
                              _buildChipIcon(
                                icon: Icons.star_rounded,
                                label: 'Важно',
                                color: const Color(0xFFFB7185),
                              ),
                            if (task.hasReminder) ...[
                              if (task.isImportant) const SizedBox(width: 8),
                              _buildChipIcon(
                                icon: Icons.notifications_active_rounded,
                                label: 'Напоминание',
                                color: const Color(0xFF38BDF8),
                              ),
                            ],
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (task.subTasks.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 18,
                      color: accent.darken(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.subTasks.where((e) => e.isCompleted).length} из ${task.subTasks.length} подзадач',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ],
              if (isPast && !task.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Упущено — перенесите или завершите',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipIcon({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.darken()),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.darken(),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    _taskKeys.removeWhere((id, _) => !_taskExistsInState(id, state));
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToPending());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddTask,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(state)),
                  if (state.locationPermissionDenied)
                    SliverToBoxAdapter(
                      child: _buildInfoBanner(
                        icon: Icons.location_off,
                        message:
                            'Чтобы определять утро, день и вечер по солнцу, разрешите доступ к геолокации.',
                        background: const Color(0xFFFFF7ED),
                        foreground: const Color(0xFFB45309),
                      ),
                    ),
                  if (state.locationPermissionPermanentlyDenied)
                    SliverToBoxAdapter(
                      child: _buildInfoBanner(
                        icon: Icons.gps_off_rounded,
                        message:
                            'Доступ к геолокации отключён. Разрешите его в настройках, чтобы расписание учитывало восход и закат.',
                        background: const Color(0xFFFFF5F5),
                        foreground: const Color(0xFFB91C1C),
                      ),
                    ),
                  if (state.errorMessage != null)
                    SliverToBoxAdapter(
                      child: _buildInfoBanner(
                        icon: Icons.error_outline,
                        message: state.errorMessage!,
                        background: const Color(0xFFFFF1F0),
                        foreground: const Color(0xFFB42318),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildProgressCard(state)),
                  SliverToBoxAdapter(child: _buildCelebrationBanner(state)),
                  SliverToBoxAdapter(child: _buildCurrentTaskCard(state)),
                  if (state.progress.total == 0)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 56,
                                color: Color(0xFFCBD5F5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'На этот день пока нет дел. Добавьте первое, чтобы стартовать!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _handleAddTask,
                                child: const Text('Добавить задачу'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _buildSegments(state),
                ],
              ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = 0.2]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
