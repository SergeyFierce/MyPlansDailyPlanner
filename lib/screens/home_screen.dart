import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../state/task_controller.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/task_list_item.dart';
import 'day_schedule_screen.dart';

enum TaskFilter { all, important }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  final DateTime _today = DateTime.now();
  TaskFilter _filter = TaskFilter.all;
  final DateFormat _monthFormat = DateFormat('LLLL y', 'ru_RU');
  final DateFormat _selectedDateFormat = DateFormat('EEEE, d MMMM y', 'ru_RU');

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_today.year, _today.month, _today.day);
    _focusedMonth = DateTime(_today.year, _today.month);
  }

  @override
  Widget build(BuildContext context) {
    final TaskController controller = context.watch<TaskController>();
    final List<Task> tasks = controller.tasksForDate(
      _selectedDate,
      importantOnly: _filter == TaskFilter.important,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои планы — Ежедневник'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Новая задача'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildMonthHeader(),
              const SizedBox(height: 16),
              _buildWeekdayRow(),
              _buildCalendarGrid(controller),
              const SizedBox(height: 24),
              Text(
                _selectedDateFormat.format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildFilterToggle(),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _EmptyState(filter: _filter)
              else
                ...tasks.map((Task task) => TaskListItem(
                      task: task,
                      onTap: () => _openSchedule(task),
                      onToggleComplete: () => controller.toggleCompleted(task.id),
                      onEdit: () => _editTask(task),
                      onDelete: () => controller.deleteTask(task.id),
                    )),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              _capitalize(_monthFormat.format(_focusedMonth)),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    final List<String> weekdays = <String>['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      children: weekdays
          .map(
            (String day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(TaskController controller) {
    final List<DateTime> days = _visibleDaysForMonth(_focusedMonth);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: days.length,
      itemBuilder: (BuildContext context, int index) {
        final DateTime day = days[index];
        final bool isToday = _isSameDay(day, _today);
        final bool isSelected = _isSameDay(day, _selectedDate);
        final bool isSameMonth = day.month == _focusedMonth.month;
        final bool hasImportant =
            controller.tasksForDate(day, importantOnly: true).isNotEmpty;
        return _CalendarDayTile(
          date: day,
          isToday: isToday,
          isSelected: isSelected,
          isSameMonth: isSameMonth,
          hasImportant: hasImportant,
          onTap: () {
            setState(() {
              _selectedDate = DateTime(day.year, day.month, day.day);
              _focusedMonth = DateTime(day.year, day.month);
            });
          },
        );
      },
    );
  }

  Widget _buildFilterToggle() {
    return SegmentedButton<TaskFilter>(
      segments: const <ButtonSegment<TaskFilter>>[
        ButtonSegment<TaskFilter>(value: TaskFilter.all, label: Text('Все дела')),
        ButtonSegment<TaskFilter>(value: TaskFilter.important, label: Text('Только важные')),
      ],
      selected: <TaskFilter>{_filter},
      onSelectionChanged: (Set<TaskFilter> value) {
        setState(() => _filter = value.first);
      },
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    });
  }

  List<DateTime> _visibleDaysForMonth(DateTime month) {
    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final int firstWeekday = (firstDay.weekday + 6) % 7; // make Monday = 0
    final DateTime start = firstDay.subtract(Duration(days: firstWeekday));
    return List<DateTime>.generate(42, (int index) => DateTime(start.year, start.month, start.day + index));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _openEditor(BuildContext context) async {
    final TaskController controller = context.read<TaskController>();
    final Task? newTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TaskEditorSheet(initialDate: _selectedDate);
      },
    );
    if (newTask != null) {
      await controller.addOrUpdateTask(newTask);
    }
  }

  Future<void> _editTask(Task task) async {
    final TaskController controller = context.read<TaskController>();
    final Task? editedTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TaskEditorSheet(initialDate: task.date, task: task);
      },
    );
    if (editedTask != null) {
      await controller.addOrUpdateTask(editedTask);
    }
  }

  void _openSchedule(Task task) {
    Navigator.of(context).push(_ScheduleRoute(date: task.date, taskId: task.id));
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isSameMonth,
    required this.hasImportant,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isSameMonth;
  final bool hasImportant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool muted = !isSameMonth;
    final Color baseColor = isSelected
        ? colors.primary
        : isToday
            ? colors.primaryContainer
            : colors.surface;
    final Color textColor = isSelected
        ? colors.onPrimary
        : muted
            ? colors.onSurfaceVariant
            : colors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday && !isSelected ? colors.primary : colors.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                date.day.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (hasImportant)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRoute extends PageRouteBuilder<void> {
  _ScheduleRoute({required DateTime date, required String taskId})
      : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (BuildContext context, Animation<double> animation,
                  Animation<double> secondaryAnimation) =>
              DayScheduleScreen(date: date, initialTaskId: taskId),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final String message = filter == TaskFilter.important
        ? 'Нет важных задач в выбранный день.'
        : 'Пока нет задач на этот день.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Нажмите «Новая задача», чтобы добавить планы.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
