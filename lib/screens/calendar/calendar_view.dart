import 'package:flutter/material.dart' hide Badge, SegmentedButton;

import '../../models/formatted_date.dart';
import '../../models/task.dart';
import '../../widgets/badge.dart';
import '../../widgets/custom_calendar.dart';
import '../../widgets/segmented_button.dart';
import '../../widgets/task_list.dart';


class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.scheduleTasks,
    required this.showOnlyImportant,
    required this.isExpanded,
    required this.onDateClick,
    required this.onTaskClick,
    required this.onUpdateTask,
    required this.onDeleteTask,
    required this.onToggleExpanded,
    required this.onToggleShowImportant,
  });

  final DateTime selectedDate;
  final DateTime today;
  final List<ScheduleTask> scheduleTasks;
  final bool showOnlyImportant;
  final bool isExpanded;
  final ValueChanged<DateTime> onDateClick;
  final ValueChanged<int> onTaskClick;
  final ValueChanged<ScheduleTask> onUpdateTask;
  final ValueChanged<int> onDeleteTask;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleShowImportant;

  List<ScheduleTask> _getTasksForDate(DateTime date) {
    return scheduleTasks
        .where(
          (task) =>
              task.date.year == date.year &&
              task.date.month == date.month &&
              task.date.day == date.day,
        )
        .toList();
  }

  FormattedDate _formatDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    const weekDays = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье'
    ];

    return FormattedDate(
      dayName: weekDays[(date.weekday + 6) % 7],
      day: date.day,
      month: months[date.month - 1],
      year: date.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = _getTasksForDate(today);
    final importantTodayTasks = todayTasks.where((task) => task.isImportant).toList();
    final completedTodayTasks = todayTasks.where((task) => task.isCompleted).toList();
    final displayedTasks = showOnlyImportant ? importantTodayTasks : todayTasks;

    final todayFormatted = _formatDate(today);

    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final cardColor = isLightTheme ? Colors.white : theme.cardColor;
    final cardElevation = isLightTheme ? 6.0 : 2.0;
    final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Text(
                    'Мои планы',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Card(
                color: cardColor,
                elevation: cardElevation,
                shadowColor: Colors.black.withOpacity(isLightTheme ? 0.08 : 0.2),
                shape: cardShape,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: CustomCalendar(
                    selected: selectedDate,
                    today: today,
                    onSelect: onDateClick,
                    importantDates:
                        scheduleTasks.where((t) => t.isImportant).map((t) => t.date).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: cardColor,
                elevation: cardElevation,
                shadowColor: Colors.black.withOpacity(isLightTheme ? 0.08 : 0.2),
                shape: cardShape,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сегодня · ${todayFormatted.day} ${todayFormatted.month}, ${todayFormatted.dayName}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Text(
                                  'Всего дел: ${todayTasks.length}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                if (completedTodayTasks.isNotEmpty)
                                  Text(
                                    '(выполнено: ${completedTodayTasks.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                if (importantTodayTasks.isNotEmpty) const SizedBox(width: 4),
                                if (importantTodayTasks.isNotEmpty)
                                  Badge.destructive(
                                    text: '${importantTodayTasks.length} важных',
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onToggleExpanded,
                            style: IconButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                            ),
                            icon: RotatedBox(
                              quarterTurns: isExpanded ? 2 : 0,
                              child: const Icon(Icons.expand_more),
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded)
                        Column(
                          children: [
                            if (importantTodayTasks.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: SegmentedButton(
                                      label: 'Все дела',
                                      selected: !showOnlyImportant,
                                      onTap: !showOnlyImportant ? null : onToggleShowImportant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SegmentedButton(
                                      label: 'Только важные',
                                      selected: showOnlyImportant,
                                      onTap: showOnlyImportant ? null : onToggleShowImportant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (displayedTasks.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.inbox, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'На сегодня задач нет',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              TaskList(
                                tasks: displayedTasks,
                                onTaskClick: onTaskClick,
                                onUpdateTask: onUpdateTask,
                                onDeleteTask: onDeleteTask,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
