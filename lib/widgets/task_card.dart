import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/time_utils.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onUpdateTask,
    required this.onOpenDetails,
    this.enableExpansion = true,
    this.collapsedSubtaskLimit = 2,
    this.onPrimaryTap,
  });

  final ScheduleTask task;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final VoidCallback onOpenDetails;
  final bool enableExpansion;
  final int collapsedSubtaskLimit;
  final VoidCallback? onPrimaryTap;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _isExpanded = false;
    }
  }

  void _handleTap() {
    if (widget.enableExpansion) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    } else {
      widget.onPrimaryTap?.call();
    }
  }

  void _toggleComplete() {
    widget.onUpdateTask(
      widget.task.copyWith(isCompleted: !widget.task.isCompleted),
    );
  }

  void _toggleSubTask(SubTask subTask) {
    final updatedSubTasks = widget.task.subTasks
        .map(
          (item) => item.id == subTask.id
              ? item.copyWith(isCompleted: !subTask.isCompleted)
              : item,
        )
        .toList();
    widget.onUpdateTask(
      widget.task.copyWith(subTasks: updatedSubTasks),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.task.isCompleted
        ? const Color(0xFFD1FADF)
        : widget.task.isImportant
            ? const Color(0xFFFDE2E4)
            : null;
    final timeLabel = formatTimeLabel(widget.task.startTime, widget.task.endTime);
    final subTasks = widget.task.subTasks;
    final hasSubTasks = subTasks.isNotEmpty;
    final completedSubTasks = subTasks.where((item) => item.isCompleted).length;
    final totalSubTasks = subTasks.length;
    final progressValue = totalSubTasks == 0 ? null : completedSubTasks / totalSubTasks;
    final showSubTasks = widget.enableExpansion && _isExpanded && hasSubTasks;
    final showExpansionIndicator = widget.enableExpansion && hasSubTasks;
    final showNavigationIndicator = !widget.enableExpansion && widget.onPrimaryTap != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: backgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _handleTap,
        onLongPress: widget.onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _toggleComplete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 2),
                      child: Icon(
                        widget.task.isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: widget.task.isCompleted
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.task.isImportant) ...[
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
                            const Spacer(),
                            if (showExpansionIndicator || showNavigationIndicator)
                              Icon(
                                showExpansionIndicator
                                    ? (_isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more)
                                    : Icons.chevron_right,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (widget.task.comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.task.comment,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (totalSubTasks > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checklist_outlined, size: 18, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Text(
                          '$completedSubTasks из $totalSubTasks подзадач',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (progressValue != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                        ),
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.checklist_rtl,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Подзадач нет',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              if (showSubTasks) ...[
                const SizedBox(height: 12),
                ...subTasks.map(
                  (subTask) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: subTask.isCompleted,
                              onChanged: (_) => _toggleSubTask(subTask),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subTask.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  decoration: subTask.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subTask.comment.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 40, top: 4),
                            child: Text(
                              subTask.comment,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
