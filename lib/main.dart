import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class Task {
  Task({required this.title, this.isImportant = false});

  final String title;
  final bool isImportant;
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
    _focusedMonth = DateTime(_today.year, _today.month);
    _tasksByDay = _generateDemoTasks();
  }

  Map<DateTime, List<Task>> _generateDemoTasks() {
    final Map<DateTime, List<Task>> tasks = <DateTime, List<Task>>{};
    void addTask(DateTime date, Task task) {
      final DateTime normalized = DateTime(date.year, date.month, date.day);
      tasks.putIfAbsent(normalized, () => <Task>[]).add(task);
    }

    addTask(_today, Task(title: 'Позвонить клиенту'));
    addTask(_today, Task(title: 'Подготовить отчёт', isImportant: true));
    addTask(_today, Task(title: 'Тренировка', isImportant: true));
    addTask(_today, Task(title: 'Купить продукты'));
    addTask(_today, Task(title: 'Прогулка с друзьями'));

    addTask(_today.add(const Duration(days: 1)),
        Task(title: 'Отправить документы', isImportant: true));
    addTask(_today.add(const Duration(days: 2)),
        Task(title: 'Работа над проектом'));
    addTask(_today.add(const Duration(days: 4)),
        Task(title: 'Презентация', isImportant: true));

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
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> todayTasks = _tasksFor(_today);
    final List<Task> importantTodayTasks =
        todayTasks.where((Task task) => task.isImportant).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои планы'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildMonthHeader(),
                const SizedBox(height: 16),
                _buildCalendar(),
                const SizedBox(height: 24),
                Text(
                  'Сегодня: ${_dayLabel(_today)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
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
    final String monthTitle =
        '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          monthTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showOnlyImportant = !_showOnlyImportant;
                  });
                },
                icon: Icon(
                  _showOnlyImportant ? Icons.visibility_off : Icons.star,
                  color:
                      _showOnlyImportant ? Colors.grey.shade600 : Colors.redAccent,
                ),
                label: Text(
                  _showOnlyImportant ? 'Показать все' : 'Только важные',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${todayTasks.length} дел, ${importantTodayTasks.length} важных',
            style: Theme.of(context).textTheme.bodyMedium,
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
                      child: Row(
                        children: <Widget>[
                          Icon(
                            task.isImportant ? Icons.star : Icons.check_circle,
                            color: task.isImportant
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task.title,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
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
