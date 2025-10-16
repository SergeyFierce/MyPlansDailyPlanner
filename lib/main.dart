import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:animations/animations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Мои планы',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 6,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.black.withOpacity(0.12),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

/* ===================== DATA MODELS ===================== */

class Task {
  final int id;
  final String title;
  final DateTime date;
  final bool isImportant;
  bool isCompleted;
  final String? description;

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.isImportant = false,
    this.isCompleted = false,
    this.description,
  });

  Task copyWith({
    String? title,
    DateTime? date,
    bool? isImportant,
    bool? isCompleted,
    String? description,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
    );
  }
}

class ScheduleTask extends Task {
  final String startTime;
  final String endTime;

  ScheduleTask({
    required int id,
    required String title,
    required DateTime date,
    required this.startTime,
    required this.endTime,
    bool isImportant = false,
    bool isCompleted = false,
    String? description,
  }) : super(
    id: id,
    title: title,
    date: date,
    isImportant: isImportant,
    isCompleted: isCompleted,
    description: description,
  );

  @override
  ScheduleTask copyWith({
    String? title,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isImportant,
    bool? isCompleted,
    String? description,
  }) {
    return ScheduleTask(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
    );
  }
}

/* ===================== MAIN SCREEN ===================== */

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ActiveView _activeView = ActiveView.calendar;

  // В React new Date(2025, 9, 16) → в Dart это 10-й месяц
  DateTime _selectedDate = DateTime(2025, 10, 16);

  // «Сегодня» в React — фиксированная дата 16.10.2025
  final DateTime _today = DateTime(2025, 10, 16);

  bool _showOnlyImportant = false;
  bool _isExpanded = false;
  int? _scrollToTaskId;

  final List<ScheduleTask> _scheduleTasks = [
    ScheduleTask(
      id: 1,
      title: "Встреча с клиентом",
      description: "Обсудить детали проекта",
      startTime: "10:00",
      endTime: "11:30",
      isImportant: true,
      isCompleted: false,
      date: DateTime(2025, 10, 16),
    ),
    ScheduleTask(
      id: 2,
      title: "Работа над отчетом",
      startTime: "14:00",
      endTime: "16:00",
      isImportant: true,
      isCompleted: false,
      date: DateTime(2025, 10, 16),
    ),
    ScheduleTask(
      id: 3,
      title: "Спортзал",
      startTime: "18:00",
      endTime: "19:30",
      isImportant: false,
      isCompleted: true,
      date: DateTime(2025, 10, 16),
    ),
    ScheduleTask(
      id: 4,
      title: "Важная презентация",
      description: "Подготовить материалы для презентации",
      startTime: "09:00",
      endTime: "10:30",
      isImportant: true,
      isCompleted: false,
      date: DateTime(2025, 10, 18),
    ),
  ];

  List<ScheduleTask> _getTasksForDate(DateTime date) {
    return _scheduleTasks
        .where((task) =>
    task.date.year == date.year &&
        task.date.month == date.month &&
        task.date.day == date.day)
        .toList();
  }

  void _handleAddTask(ScheduleTask task) {
    setState(() {
      final newId = _scheduleTasks.isEmpty
          ? 1
          : _scheduleTasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
      _scheduleTasks.add(ScheduleTask(
        id: newId,
        title: task.title,
        date: task.date,
        startTime: task.startTime,
        endTime: task.endTime,
        isImportant: task.isImportant,
        isCompleted: task.isCompleted,
        description: task.description,
      ));
    });
  }

  void _handleUpdateTask(ScheduleTask updatedTask) {
    setState(() {
      final index = _scheduleTasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) _scheduleTasks[index] = updatedTask;
    });
  }

  void _handleDeleteTask(int id) {
    setState(() {
      _scheduleTasks.removeWhere((t) => t.id == id);
    });
  }

  void _handleDateClick(DateTime date) {
    setState(() {
      _selectedDate = date;
      _activeView = ActiveView.schedule;
      _scrollToTaskId = null;
    });
  }

  void _handleTaskClick(int taskId) {
    setState(() {
      _activeView = ActiveView.schedule;
      _scrollToTaskId = taskId;
    });
  }

  void _handleBackToCalendar() {
    setState(() {
      _activeView = ActiveView.calendar;
      _scrollToTaskId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Градиент как в React (from-blue-50 to-indigo-50)
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              final isCalendar = (child.key as ValueKey?)?.value == 'calendar';
              final offset =
              isCalendar ? const Offset(-0.05, 0) : const Offset(0.05, 0);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: offset, end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              );
            },
            child: _activeView == ActiveView.calendar
                ? CalendarView(
              key: const ValueKey('calendar'),
              selectedDate: _selectedDate,
              today: _today,
              scheduleTasks: _scheduleTasks,
              showOnlyImportant: _showOnlyImportant,
              isExpanded: _isExpanded,
              onDateClick: _handleDateClick,
              onTaskClick: _handleTaskClick,
              onUpdateTask: _handleUpdateTask,
              onDeleteTask: _handleDeleteTask,
              onToggleExpanded: () =>
                  setState(() => _isExpanded = !_isExpanded),
              onToggleShowImportant: () => setState(
                      () => _showOnlyImportant = !_showOnlyImportant),
            )
                : DayScheduleView(
              key: const ValueKey('schedule'),
              selectedDate: _selectedDate,
              tasks: _getTasksForDate(_selectedDate),
              scrollToTaskId: _scrollToTaskId,
              onAddTask: _handleAddTask,
              onUpdateTask: _handleUpdateTask,
              onDeleteTask: _handleDeleteTask,
              onBack: _handleBackToCalendar,
            ),
          ),
        ),
      ),
    );
  }
}

enum ActiveView { calendar, schedule }

class FormattedDate {
  final String dayName;
  final int day;
  final String month;
  final int year;

  FormattedDate({
    required this.dayName,
    required this.day,
    required this.month,
    required this.year,
  });
}

/* ===================== CALENDAR VIEW ===================== */

class CalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime today;
  final List<ScheduleTask> scheduleTasks;
  final bool showOnlyImportant;
  final bool isExpanded;
  final Function(DateTime) onDateClick;
  final Function(int) onTaskClick;
  final Function(ScheduleTask) onUpdateTask;
  final Function(int) onDeleteTask;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleShowImportant;

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

  List<ScheduleTask> _getTasksForDate(DateTime date) {
    return scheduleTasks
        .where((task) =>
    task.date.year == date.year &&
        task.date.month == date.month &&
        task.date.day == date.day)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = _getTasksForDate(today);
    final importantTodayTasks =
    todayTasks.where((task) => task.isImportant).toList();
    final completedTodayTasks =
    todayTasks.where((task) => task.isCompleted).toList();
    final displayedTasks =
    showOnlyImportant ? importantTodayTasks : todayTasks;

    final todayFormatted = _formatDate(today);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Text(
                    "Мои планы",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // Календарь (карточка)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomCalendar(
                    selected: selectedDate,
                    onSelect: onDateClick,
                    importantDates: scheduleTasks
                        .where((t) => t.isImportant)
                        .map((t) => t.date)
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // «Дела на сегодня»
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${todayFormatted.day} ${todayFormatted.month}, ${todayFormatted.dayName}",
                        style:
                        const TextStyle(fontSize: 16, color: Colors.grey),
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
                                  "Всего дел: ${todayTasks.length}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                                if (completedTodayTasks.isNotEmpty)
                                  Text(
                                    "(выполнено: ${completedTodayTasks.length})",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                if (importantTodayTasks.isNotEmpty)
                                  const SizedBox(width: 4),
                                if (importantTodayTasks.isNotEmpty)
                                  Badge.destructive(
                                    text:
                                    "${importantTodayTasks.length} важных",
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onToggleExpanded,
                            style: IconButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                            ),
                            icon: AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more),
                            ),
                          ),
                        ],
                      ),

                      ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            // плавная прозрачность + вертикальное изменение высоты
                            return FadeTransition(
                              opacity: anim,
                              child: SizeTransition(
                                sizeFactor: anim,           // от 0 до 1 по вертикали
                                axis: Axis.vertical,
                                axisAlignment: -1.0,        // «раскрываемся» сверху вниз
                                child: child,
                              ),
                            );
                          },
                          child: isExpanded
                              ? Column(
                            key: const ValueKey('expanded'),
                            children: [
                              if (importantTodayTasks.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SegmentedButton(
                                        label: "Все дела",
                                        selected: !showOnlyImportant,
                                        onTap: !showOnlyImportant ? null : onToggleShowImportant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _SegmentedButton(
                                        label: "Только важные",
                                        selected: showOnlyImportant,
                                        onTap: showOnlyImportant ? null : onToggleShowImportant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),

                              // список с собственной анимацией переключения фильтров
                              _AnimatedTaskList(
                                showOnlyImportant: showOnlyImportant,
                                allTasks: todayTasks,
                                importantTasks: importantTodayTasks,
                                displayedTasks: displayedTasks,
                                onTaskClick: onTaskClick,
                                onUpdateTask: onUpdateTask,
                                onDeleteTask: onDeleteTask,
                              ),
                            ],
                          )
                              : const SizedBox.shrink(key: ValueKey('collapsed')),
                        ),
                      )
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

  FormattedDate _formatDate(DateTime date) {
    // День недели: DateTime.weekday (1=Пн ... 7=Вс)
    const days = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье'
    ];
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

    return FormattedDate(
      dayName: days[date.weekday - 1],
      day: date.day,
      month: months[date.month - 1],
      year: date.year,
    );
  }
}

class _AnimatedTaskList extends StatelessWidget {
  final bool showOnlyImportant;
  final List<ScheduleTask> allTasks;
  final List<ScheduleTask> importantTasks;
  final List<ScheduleTask> displayedTasks;
  final Function(int) onTaskClick;
  final Function(ScheduleTask) onUpdateTask;
  final Function(int) onDeleteTask;

  const _AnimatedTaskList({
    required this.showOnlyImportant,
    required this.allTasks,
    required this.importantTasks,
    required this.displayedTasks,
    required this.onTaskClick,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    // ключ завязан только на тип фильтра, чтобы не триггерить лишние перестройки
    final keyString = showOnlyImportant ? 'imp' : 'all';

    final Widget content = displayedTasks.isEmpty
        ? const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Нет задач', style: TextStyle(color: Colors.grey)),
      ),
    )
        : TaskList(
      tasks: displayedTasks,
      onTaskClick: (id) => onTaskClick(id),
      onUpdateTask: onUpdateTask,
      onDeleteTask: onDeleteTask,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,

      // Стекуем предыдущего и текущего ребёнка — скролл не дёргается.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),

      // Только прозрачность, без Size/Slide — высота меняется мгновенно.
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),

      child: KeyedSubtree(
        key: ValueKey(keyString),
        child: content,
      ),
    );
  }
}



/* ===================== DAY SCHEDULE VIEW ===================== */

class DayScheduleView extends StatefulWidget {
  final DateTime selectedDate;
  final List<ScheduleTask> tasks;
  final int? scrollToTaskId;
  final Function(ScheduleTask) onAddTask;
  final Function(ScheduleTask) onUpdateTask;
  final Function(int) onDeleteTask;
  final VoidCallback onBack;

  const DayScheduleView({
    super.key,
    required this.selectedDate,
    required this.tasks,
    this.scrollToTaskId,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
    required this.onBack,
  });

  @override
  State<DayScheduleView> createState() => _DayScheduleViewState();
}

class _DayScheduleViewState extends State<DayScheduleView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToTaskId != null) _scrollToTask();
    });
  }

  void _scrollToTask() {
    final taskIndex =
    widget.tasks.indexWhere((task) => task.id == widget.scrollToTaskId);
    if (taskIndex != -1) {
      const itemHeight = 120.0;
      final scrollOffset = taskIndex * itemHeight;
      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleAddTask() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        selectedDate: widget.selectedDate,
        onAddTask: widget.onAddTask,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(widget.selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(
          "${formattedDate.day} ${formattedDate.month}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleAddTask,
          ),
        ],
      ),
      body: widget.tasks.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "На этот день задач нет",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          return TaskCard(
            task: task,
            onTap: () => _showTaskDetails(task),
            onToggleComplete: () {
              widget.onUpdateTask(
                  task.copyWith(isCompleted: !task.isCompleted));
            },
            onDelete: () => widget.onDeleteTask(task.id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTaskDetails(ScheduleTask task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(
        task: task,
        onUpdateTask: widget.onUpdateTask,
        onDeleteTask: widget.onDeleteTask,
      ),
    );
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

    return FormattedDate(
      dayName: '',
      day: date.day,
      month: months[date.month - 1],
      year: date.year,
    );
  }
}

/* ===================== CUSTOM CALENDAR ===================== */

class CustomCalendar extends StatefulWidget {
  final DateTime selected;
  final Function(DateTime) onSelect;
  final List<DateTime> importantDates;

  const CustomCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.importantDates,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _currentMonth;
  final List<String> _weekDays = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selected.year, widget.selected.month);
  }

  List<DateTime> _getMonthDays() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final days = <DateTime>[];
    for (var i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // prepend предыдущие дни до понедельника
    final firstWeekday = (firstDay.weekday + 6) % 7; // 0=Пн ... 6=Вс
    for (var i = 0; i < firstWeekday; i++) {
      days.insert(0, firstDay.subtract(Duration(days: i + 1)));
    }

    // append хвост до конца сетки (целые недели)
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }

    return days;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isImportantDate(DateTime date) {
    return widget.importantDates.any((d) =>
    d.year == date.year && d.month == date.month && d.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    final days = _getMonthDays();
    const monthNames = [
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
      'Декабрь'
    ];

    return Column(
      children: [
        // Заголовок
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: _previousMonth, icon: const Icon(Icons.chevron_left)),
            Text(
              '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 12),

        // Дни недели
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 7,
          itemBuilder: (_, i) => Center(
            child: Text(
              _weekDays[i],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Дни месяца
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (_, index) {
            final day = days[index];
            final isCurrentMonth = day.month == _currentMonth.month;
            final isSelected = day.day == widget.selected.day &&
                day.month == widget.selected.month &&
                day.year == widget.selected.year;
            final isImportant = _isImportantDate(day);

            return GestureDetector(
              onTap: () => widget.onSelect(day),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCurrentMonth
                            ? Colors.black
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isImportant)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/* ===================== TASK LIST ===================== */

class TaskList extends StatelessWidget {
  final List<ScheduleTask> tasks;
  final Function(int) onTaskClick;
  final Function(ScheduleTask) onUpdateTask;
  final Function(int) onDeleteTask;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onTaskClick,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks
          .map((task) => TaskCard(
        task: task,
        onTap: () => onTaskClick(task.id),
        onToggleComplete: () {
          onUpdateTask(task.copyWith(isCompleted: !task.isCompleted));
        },
        onDelete: () => onDeleteTask(task.id),
      ))
          .toList(),
    );
  }
}

/* ===================== TASK CARD ===================== */

class TaskCard extends StatelessWidget {
  final ScheduleTask task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            leading: IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color:
                task.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
              ),
              onPressed: onToggleComplete,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration:
                task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty) ...[
                  Text(task.description!),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${task.startTime} - ${task.endTime}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isImportant)
                  const Icon(Icons.label_important, color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== DIALOGS ===================== */

class AddTaskDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(ScheduleTask) onAddTask;

  const AddTaskDialog({
    super.key,
    required this.selectedDate,
    required this.onAddTask,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  bool _isImportant = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить задачу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(labelText: 'Начало (HH:mm)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(labelText: 'Конец (HH:mm)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Важная задача'),
              value: _isImportant,
              onChanged: (value) => setState(() => _isImportant = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final task = ScheduleTask(
              id: 0, // заменится при добавлении
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              startTime: _startTimeController.text.trim(),
              endTime: _endTimeController.text.trim(),
              isImportant: _isImportant,
              date: widget.selectedDate,
            );
            widget.onAddTask(task);
            Navigator.pop(context);
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

class TaskDetailsDialog extends StatefulWidget {
  final ScheduleTask task;
  final Function(ScheduleTask) onUpdateTask;
  final Function(int) onDeleteTask;

  const TaskDetailsDialog({
    super.key,
    required this.task,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late bool _isImportant;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description ?? '');
    _startTimeController = TextEditingController(text: widget.task.startTime);
    _endTimeController = TextEditingController(text: widget.task.endTime);
    _isImportant = widget.task.isImportant;
    _isCompleted = widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать задачу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(labelText: 'Начало'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(labelText: 'Конец'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Важная'),
              value: _isImportant,
              onChanged: (value) => setState(() => _isImportant = value),
            ),
            SwitchListTile(
              title: const Text('Выполнена'),
              value: _isCompleted,
              onChanged: (value) => setState(() => _isCompleted = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            widget.onDeleteTask(widget.task.id);
            Navigator.pop(context);
          },
          child: const Text('Удалить', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedTask = widget.task.copyWith(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              startTime: _startTimeController.text.trim(),
              endTime: _endTimeController.text.trim(),
              isImportant: _isImportant,
              isCompleted: _isCompleted,
            );
            widget.onUpdateTask(updatedTask);
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

/* ===================== MINI UI HELPERS ===================== */

class Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const Badge._(this.text, this.color, this.textColor, {super.key});

  // ⬇️ фикс: убрали super.key и прокинули key в redirecting-конструктор
  const Badge.destructive({Key? key, required String text})
      : this._(text, const Color(0xFFDC2626), Colors.white, key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}


class _SegmentedButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SegmentedButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: border,
        side: BorderSide(
          color: selected ? const Color(0xFF4F46E5) : const Color(0x334F46E5),
          width: 1.2,
        ),
        foregroundColor: selected ? Colors.white : const Color(0xFF4F46E5),
        backgroundColor: selected ? const Color(0xFF4F46E5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }
}
