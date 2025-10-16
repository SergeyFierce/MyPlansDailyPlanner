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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildMonthHeader(),
                const SizedBox(height: 16),
                _buildTodayBanner(context),
                const SizedBox(height: 16),
                _buildCalendar(),
                const SizedBox(height: 24),
                _buildTasksSummaryCard(
                  context,
                  todayTasks: todayTasks,
                  importantTodayTasks: importantTodayTasks,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Мои планы',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButton<int>(
              value: _selectedMonth,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
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
            DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 8),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              if (index < leadingEmptyCells) {
                return const SizedBox();
              }
              final int dayNumber = index - leadingEmptyCells + 1;
              final DateTime dayDate =
                  DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final bool isToday = dayDate.year == _today.year &&
                  dayDate.month == _today.month &&
                  dayDate.day == _today.day;
              final List<Task> tasks = _tasksFor(dayDate);
              final bool hasImportant =
                  tasks.any((Task task) => task.isImportant);

              return _CalendarDayCell(
                day: dayNumber,
                isToday: isToday,
                hasImportant: hasImportant,
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
    final List<Task> visibleTasks = _showOnlyImportant
        ? importantTodayTasks
        : todayTasks;
    final int completedCount =
        todayTasks.where((Task task) => task.isCompleted).length;

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Дела на сегодня',
                style: titleStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
              ToggleButtons(
                isSelected: <bool>[!_showOnlyImportant, _showOnlyImportant],
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 110),
                onPressed: (int index) {
                  setState(() {
                    _showOnlyImportant = index == 1;
                  });
                },
                children: const <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Все дела'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Только важные'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _SummaryBadge(
                label: 'Всего дел',
                value: '${todayTasks.length}',
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              _SummaryBadge(
                label: 'Важных',
                value: '${importantTodayTasks.length}',
                backgroundColor: Colors.redAccent,
              ),
              _SummaryBadge(
                label: 'Выполнено',
                value: '$completedCount',
                backgroundColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleTasks.isEmpty)
            const Text('Нет дел для отображения')
          else
            Column(
              children: visibleTasks
                  .map(
                    (Task task) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _TaskListTile(
                        task: task,
                        timeRange: _formatTimeRange(task),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.timeRange,
  });

  final Task task;
  final String timeRange;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color borderColor = task.isImportant
        ? Colors.redAccent.withOpacity(0.3)
        : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted
                  ? Colors.green.withOpacity(0.15)
                  : colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              task.isCompleted ? Icons.check : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (task.isImportant)
                      const Icon(
                        Icons.star,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  timeRange,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                if (task.description != null) ...<Widget>[
                  const SizedBox(height: 6),
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
            children: const <Widget>[
              Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
              SizedBox(height: 12),
              Icon(Icons.delete_outline, color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.hasImportant,
  });

  final int day;
  final bool isToday;
  final bool hasImportant;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: isToday ? colorScheme.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? colorScheme.primary : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isToday ? colorScheme.primary : Colors.black87,
              ),
            ),
          ),
        ),
        if (hasImportant)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
