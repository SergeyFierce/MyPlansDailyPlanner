import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../state/task_controller.dart';
import '../widgets/task_editor_sheet.dart';

class DayScheduleScreen extends StatefulWidget {
  const DayScheduleScreen({
    super.key,
    required this.date,
    this.initialTaskId,
  });

  final DateTime date;
  final String? initialTaskId;

  @override
  State<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends State<DayScheduleScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _hourHeight = 72;
  static const double _labelWidth = 52;
  final DateFormat _titleFormat = DateFormat('d MMMM y, EEEE', 'ru_RU');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTask());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TaskController controller = context.watch<TaskController>();
    final List<Task> tasks = controller.tasksForDate(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание дня\n${_titleFormat.format(widget.date)}'),
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildTimeline(tasks),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить задачу'),
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

  Widget _buildTimeline(List<Task> tasks) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double availableWidth = maxWidth - _labelWidth - 16;
        final List<_PositionedTask> layouts = _calculateTaskLayout(tasks);
        final List<Widget> children = <Widget>[];

        for (int hour = 0; hour <= 24; hour++) {
          final double top = hour * _hourHeight;
          children.add(Positioned(
            top: top,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 1,
              child: Container(
                color: hour == 0 ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ));
          if (hour < 24) {
            children.add(Positioned(
              top: top,
              left: 8,
              width: _labelWidth - 16,
              child: Text(
                hour.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ));
          }
        }

        for (final _PositionedTask layout in layouts) {
          final double width = (availableWidth - (layout.totalColumns - 1) * 8) / layout.totalColumns;
          final double left = _labelWidth + layout.column * (width + 8);
          final double top = layout.task.startMinutes / 60 * _hourHeight;
          final double height = max((layout.task.endMinutes - layout.task.startMinutes) / 60 * _hourHeight, 48);
          children.add(Positioned(
            top: top,
            left: left,
            width: width,
            height: height,
            child: _ScheduleTaskCard(
              task: layout.task,
              onTap: () => context.read<TaskController>().toggleCompleted(layout.task.id),
            ),
          ));
        }

        return SizedBox(
          height: _hourHeight * 24,
          child: Stack(children: children),
        );
      },
    );
  }

  List<_PositionedTask> _calculateTaskLayout(List<Task> tasks) {
    final List<Task> sorted = List<Task>.of(tasks)
      ..sort((Task a, Task b) => a.startMinutes.compareTo(b.startMinutes));
    final List<_PositionedTask> result = <_PositionedTask>[];
    final List<_PositionedTask> active = <_PositionedTask>[];
    List<_PositionedTask> cluster = <_PositionedTask>[];
    int clusterColumns = 0;

    void finalizeCluster() {
      if (cluster.isEmpty) return;
      for (final _PositionedTask item in cluster) {
        item.totalColumns = max(clusterColumns, 1);
      }
      cluster = <_PositionedTask>[];
      clusterColumns = 0;
    }

    for (final Task task in sorted) {
      active.removeWhere((_PositionedTask item) => item.task.endMinutes <= task.startMinutes);
      if (active.isEmpty) {
        finalizeCluster();
      }
      final Set<int> usedColumns = active.map((_PositionedTask item) => item.column).toSet();
      int column = 0;
      while (usedColumns.contains(column)) {
        column++;
      }
      final _PositionedTask layout = _PositionedTask(task: task, column: column);
      active.add(layout);
      cluster.add(layout);
      clusterColumns = max(clusterColumns, column + 1);
      result.add(layout);
    }

    finalizeCluster();
    return result;
  }

  Future<void> _openEditor(BuildContext context) async {
    final TaskController controller = context.read<TaskController>();
    final Task? task = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TaskEditorSheet(initialDate: widget.date);
      },
    );
    if (task != null) {
      await controller.addOrUpdateTask(task);
    }
  }

  void _scrollToTask() {
    final String? taskId = widget.initialTaskId;
    if (taskId == null || !_scrollController.hasClients) {
      return;
    }
    final Task? task = context.read<TaskController>().findById(taskId);
    if (task == null) return;
    final double targetOffset = max(task.startMinutes / 60 * _hourHeight - 120, 0);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PositionedTask {
  _PositionedTask({required this.task, required this.column});

  final Task task;
  final int column;
  int totalColumns = 1;
}

class _ScheduleTaskCard extends StatelessWidget {
  const _ScheduleTaskCard({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateFormat formatter = DateFormat.Hm('ru_RU');
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? colors.primaryContainer.withOpacity(0.4)
              : colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted ? colors.primary : colors.primary.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimaryContainer,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
                if (task.isImportant)
                  Icon(Icons.flag, size: 18, color: colors.onPrimaryContainer),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatter.format(DateTime(0, 1, 1, task.startMinutes ~/ 60, task.startMinutes % 60))} – '
              '${formatter.format(DateTime(0, 1, 1, task.endMinutes ~/ 60, task.endMinutes % 60))}',
              style: textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer.withOpacity(0.9)),
            ),
            if (task.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                task.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
