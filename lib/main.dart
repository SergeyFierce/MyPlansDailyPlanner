import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class Task {
  Task({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.isImportant = false,
    this.isCompleted = false,
  });

  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? description;
  final bool isImportant;
  final bool isCompleted;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Plans - Daily Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        scaffoldBackgroundColor: const Color(0xFFF4F5F9),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _focusedMonth;
  late int _selectedMonth;
  late int _selectedYear;
  bool _showOnlyImportant = false;
  late final Map<DateTime, List<Task>> _tasksByDay;

  static final List<String> _monthNames = <String>[
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static final List<String> _weekdayNames = <String>[
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(initializeDateFormatting('ru_RU'));
    _selectedMonth = _today.month;
    _selectedYear = _today.year;
    _focusedMonth = DateTime(_selectedYear, _selectedMonth);
    _tasksByDay = _generateDemoTasks();
  }

  Map<DateTime, List<Task>> _generateDemoTasks() {
    final Map<DateTime, List<Task>> tasks = <DateTime, List<Task>>{};
    void addTask(DateTime date, Task task) {
      final DateTime normalized = DateTime(date.year, date.month, date.day);
      tasks.putIfAbsent(normalized, () => <Task>[]).add(task);
    }

    addTask(
      _today,
      Task(
        title: 'Встреча с клиентом',
        description: 'Обсудить детали проекта',
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        isImportant: true,
      ),
    );
    addTask(
      _today,
      Task(
        title: 'Подготовить отчёт',
        description: 'Финансовый отчёт за неделю',
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        isCompleted: true,
      ),
    );
    addTask(
      _today,
      Task(
        title: 'Спортзал',
        description: 'Тренировка на выносливость',
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        isImportant: true,
      ),
    );
    addTask(
      _today,
      Task(
        title: 'Купить продукты',
        startTime: const TimeOfDay(hour: 19, minute: 30),
        endTime: const TimeOfDay(hour: 20, minute: 0),
      ),
    );
    addTask(
      _today,
      Task(
        title: 'Прогулка',
        description: 'Вечером в парке',
        startTime: const TimeOfDay(hour: 20, minute: 30),
        endTime: const TimeOfDay(hour: 21, minute: 30),
        isCompleted: true,
      ),
    );

    addTask(
      _today.add(const Duration(days: 1)),
      Task(
        title: 'Отправить документы',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 30),
        isImportant: true,
      ),
    );
    addTask(
      _today.add(const Duration(days: 2)),
      Task(
        title: 'Работа над проектом',
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
      ),
    );
    addTask(
      _today.add(const Duration(days: 4)),
      Task(
        title: 'Презентация',
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        isImportant: true,
      ),
    );

    return tasks;
  }

  List<Task> _tasksFor(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return _tasksByDay[normalized] ?? <Task>[];
  }

  String _dayLabel(DateTime date) {
    final DateFormat formatter = DateFormat('d MMMM, EEEE', 'ru_RU');
    return formatter.format(date);
  }

  int get _daysInFocusedMonth {
    final DateTime firstDayNextMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  void _changeMonth(int offset) {
    setState(() {
      final DateTime next =
          DateTime(_focusedMonth.year, _focusedMonth.month + offset);
      _selectedMonth = next.month;
      _selectedYear = next.year;
      _focusedMonth = DateTime(_selectedYear, _selectedMonth);
    });
  }

  void _onMonthChanged(int? newMonth) {
    if (newMonth == null) return;
    setState(() {
      _selectedMonth = newMonth;
      _focusedMonth = DateTime(_selectedYear, _selectedMonth);
    });
  }

  void _onYearChanged(int? newYear) {
    if (newYear == null) return;
    setState(() {
      _selectedYear = newYear;
      _focusedMonth = DateTime(_selectedYear, _selectedMonth);
    });
  }

  List<int> get _availableYears {
    final int currentYear = _today.year;
    return List<int>.generate(7, (int index) => currentYear - 2 + index);
  }

  String _formatTimeRange(Task task) {
    final DateFormat formatter = DateFormat('HH:mm');
    final DateTime referenceDate = DateTime(0, 1, 1);
    final DateTime startDateTime = DateTime(referenceDate.year, referenceDate.month,
        referenceDate.day, task.startTime.hour, task.startTime.minute);
    final DateTime endDateTime = DateTime(referenceDate.year, referenceDate.month,
        referenceDate.day, task.endTime.hour, task.endTime.minute);
    return '${formatter.format(startDateTime)} - ${formatter.format(endDateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> todayTasks = _tasksFor(_today);
    final List<Task> importantTodayTasks =
        todayTasks.where((Task task) => task.isImportant).toList();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double minHeight =
                constraints.maxHeight.isFinite ? constraints.maxHeight : 0;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildAppHeader(context),
                    const SizedBox(height: 20),
                    _buildTodayBanner(context),
                    const SizedBox(height: 16),
                    _buildCalendar(),
                    const SizedBox(height: 24),
                    _buildTasksSummaryCard(
                      context,
                      todayTasks: todayTasks,
                      importantTodayTasks: importantTodayTasks,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryBadges(todayTasks, importantTodayTasks),
                    const SizedBox(height: 12),
                    ..._buildTaskCards(
                      context,
                      todayTasks: visibleTasksForToday(todayTasks),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Task> visibleTasksForToday(List<Task> todayTasks) {
    if (_showOnlyImportant) {
      return todayTasks.where((Task task) => task.isImportant).toList();
    }
    return todayTasks;
  }

  Widget _buildAppHeader(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Мои планы',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  _DropdownChip<int>(
                    value: _selectedMonth,
                    items: List<DropdownMenuItem<int>>.generate(
                      _monthNames.length,
                      (int index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(_monthNames[index]),
                      ),
                    ),
                    onChanged: _onMonthChanged,
                  ),
                  const SizedBox(width: 8),
                  _DropdownChip<int>(
                    value: _selectedYear,
                    items: _availableYears
                        .map(
                          (int year) => DropdownMenuItem<int>(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: _onYearChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          children: <Widget>[
            _RoundIconButton(
              icon: Icons.chevron_left,
              onTap: () => _changeMonth(-1),
            ),
            const SizedBox(height: 8),
            _RoundIconButton(
              icon: Icons.chevron_right,
              onTap: () => _changeMonth(1),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTodayBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Сегодня',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _dayLabel(_today),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          Icon(
            Icons.calendar_today_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final DateTime firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int leadingEmptyCells = (firstDayOfMonth.weekday + 6) % 7;
    final int itemCount = leadingEmptyCells + _daysInFocusedMonth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekdayNames
                .map(
                  (String name) => Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB0B4C0),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              if (index < leadingEmptyCells) {
                return const SizedBox();
              }
              final int dayNumber = index - leadingEmptyCells + 1;
              final DateTime dayDate =
                  DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final List<Task> tasks = _tasksFor(dayDate);
              return _CalendarDayCell(
                day: dayNumber,
                date: dayDate,
                today: _today,
                tasks: tasks,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSummaryCard(
    BuildContext context, {
    required List<Task> todayTasks,
    required List<Task> importantTodayTasks,
  }) {
    final TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Дела на сегодня',
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormat('d MMMM', 'ru_RU').format(_today)}, ${DateFormat('EEEE', 'ru_RU').format(_today)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          ToggleButtons(
            isSelected: <bool>[!_showOnlyImportant, _showOnlyImportant],
            onPressed: (int index) {
              setState(() {
                _showOnlyImportant = index == 1;
              });
            },
            borderRadius: BorderRadius.circular(30),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
            selectedColor: Colors.white,
            fillColor: Theme.of(context).colorScheme.primary,
            color: Colors.grey.shade600,
            children: const <Widget>[
              Text('Все дела'),
              Text('Только важные'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadges(
    List<Task> todayTasks,
    List<Task> importantTodayTasks,
  ) {
    final int completedCount =
        todayTasks.where((Task task) => task.isCompleted).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _SummaryBadge(
          label: 'Всего дел',
          count: todayTasks.length,
          backgroundColor: const Color(0xFFE8E5FF),
          foregroundColor: const Color(0xFF6C63FF),
          icon: Icons.list_alt,
        ),
        _SummaryBadge(
          label: 'Важных',
          count: importantTodayTasks.length,
          backgroundColor: const Color(0xFFFDE6E7),
          foregroundColor: const Color(0xFFE64A4A),
          icon: Icons.priority_high,
        ),
        _SummaryBadge(
          label: 'Выполнено',
          count: completedCount,
          backgroundColor: const Color(0xFFDDF5E6),
          foregroundColor: const Color(0xFF3F9A57),
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }

  List<Widget> _buildTaskCards(
    BuildContext context, {
    required List<Task> todayTasks,
  }) {
    if (todayTasks.isEmpty) {
      return <Widget>[
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: const <Widget>[
              Icon(Icons.inbox_outlined, color: Colors.grey, size: 36),
              SizedBox(height: 12),
              Text(
                'На сегодня задач нет',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Добавьте новые задачи, чтобы заполнить ваш день',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return todayTasks
        .map(
          (Task task) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _TaskCard(
              task: task,
              timeRange: _formatTimeRange(task),
            ),
          ),
        )
        .toList();
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String label;
  final int count;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.timeRange,
  });

  final Task task;
  final String timeRange;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color statusColor =
        task.isCompleted ? const Color(0xFF3F9A57) : colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TaskStatusIndicator(color: statusColor, completed: task.isCompleted),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Icon(
                          task.isImportant ? Icons.star : Icons.star_border,
                          color: task.isImportant
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Icon(Icons.access_time, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          timeRange,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                    if (task.description != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        task.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: <Widget>[
                  Icon(Icons.edit_outlined, color: Colors.grey.shade500, size: 20),
                  const SizedBox(height: 12),
                  Icon(Icons.delete_outline, color: Colors.grey.shade500, size: 20),
                ],
              ),
            ],
          ),
        ),
        if (task.isImportant)
          Positioned(
            top: -6,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Важное',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A3C00),
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskStatusIndicator extends StatelessWidget {
  const _TaskStatusIndicator({
    required this.color,
    required this.completed,
  });

  final Color color;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Icon(
        completed ? Icons.check : Icons.radio_button_unchecked,
        color: color,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.date,
    required this.today,
    required this.tasks,
  });

  final int day;
  final DateTime date;
  final DateTime today;
  final List<Task> tasks;

  bool get _isToday =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool hasImportant = tasks.any((Task task) => task.isImportant);
    final bool hasCompleted = tasks.any((Task task) => task.isCompleted);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _isToday ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isToday ? colorScheme.primary : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _isToday ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        if (tasks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (hasImportant)
                _CalendarDot(color: Colors.redAccent),
              if (hasCompleted) ...<Widget>[
                if (hasImportant) const SizedBox(width: 4),
                _CalendarDot(color: const Color(0xFF3F9A57)),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _CalendarDot extends StatelessWidget {
  const _CalendarDot({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: DropdownButton<T>(
          value: value,
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: Theme.of(context).textTheme.bodyLarge,
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
