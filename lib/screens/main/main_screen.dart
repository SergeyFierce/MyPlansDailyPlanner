import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../calendar/calendar_view.dart';
import '../day_schedule/day_schedule_view.dart';

enum ActiveView { calendar, schedule }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ActiveView _activeView = ActiveView.calendar;
  final DateTime _today = DateTime(2025, 10, 16);
  late DateTime _selectedDate;
  bool _showOnlyImportant = false;
  bool _isExpanded = false;
  int? _scrollToTaskId;

  final List<ScheduleTask> _scheduleTasks = [
    ScheduleTask(
      id: 1,
      title: 'Позвонить маме',
      startTime: '09:00',
      endTime: '09:00',
      isImportant: true,
      date: DateTime(2025, 10, 16),
      comment: 'Порадовать её новостями из жизни.',
      subTasks: const [
        SubTask(
          id: 101,
          title: 'Составить список вопросов',
          comment: 'Вспомнить про отпуск и здоровье.',
        ),
      ],
    ),
    ScheduleTask(
      id: 2,
      title: 'Командный созвон',
      startTime: '09:30',
      endTime: '10:30',
      isImportant: true,
      date: DateTime(2025, 10, 16),
      comment: 'Обсуждаем прогресс по релизу.',
      subTasks: const [
        SubTask(
          id: 102,
          title: 'Подготовить повестку',
          comment: 'Собрать вопросы от команды.',
        ),
        SubTask(
          id: 103,
          title: 'Разослать материалы',
          comment: 'Слайды и ссылки на прототип.',
        ),
      ],
    ),
    ScheduleTask(
      id: 3,
      title: 'Работа над отчётом',
      startTime: '12:00',
      endTime: '14:00',
      isImportant: false,
      isCompleted: false,
      date: DateTime(2025, 10, 16),
      comment: 'Собрать цифры за квартал.',
      subTasks: const [
        SubTask(
          id: 104,
          title: 'Собрать данные из CRM',
          comment: 'Выгрузить экспорт в Excel.',
        ),
        SubTask(
          id: 105,
          title: 'Обновить диаграммы',
          comment: 'Добавить новые метрики.',
        ),
      ],
    ),
    ScheduleTask(
      id: 4,
      title: 'Тренировка',
      startTime: '18:00',
      endTime: '19:30',
      isCompleted: true,
      date: DateTime(2025, 10, 16),
      comment: 'Поддерживаем форму.',
      subTasks: const [
        SubTask(
          id: 106,
          title: 'Разминка',
          isCompleted: true,
          comment: 'Лёгкая растяжка.',
        ),
        SubTask(
          id: 107,
          title: 'Кардио',
          comment: 'Интервальный бег 20 минут.',
        ),
      ],
    ),
    ScheduleTask(
      id: 5,
      title: 'Презентация проекта',
      startTime: '10:00',
      endTime: '11:30',
      isImportant: true,
      date: DateTime(2025, 10, 18),
      comment: 'Готовим демо для партнёров.',
      subTasks: const [
        SubTask(
          id: 108,
          title: 'Собрать слайды',
          comment: 'Обновить блок с метриками.',
        ),
        SubTask(
          id: 109,
          title: 'Репетиция выступления',
          comment: 'С таймером и обратной связью.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
  }

  List<ScheduleTask> _getTasksForDate(DateTime date) {
    return _scheduleTasks
        .where(
          (task) =>
              task.date.year == date.year &&
              task.date.month == date.month &&
              task.date.day == date.day,
        )
        .toList();
  }

  void _handleAddTask(ScheduleTask task) {
    setState(() {
      final newId = _scheduleTasks.isEmpty
          ? 1
          : _scheduleTasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
      _scheduleTasks.add(
        ScheduleTask(
          id: newId,
          title: task.title,
          date: task.date,
          startTime: task.startTime,
          endTime: task.endTime,
          isImportant: task.isImportant,
          isCompleted: task.isCompleted,
          subTasks: task.subTasks,
          comment: task.comment,
        ),
      );
      _scrollToTaskId = newId;
    });
  }

  void _handleUpdateTask(ScheduleTask updatedTask) {
    setState(() {
      final index = _scheduleTasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _scheduleTasks[index] = updatedTask;
      }
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
    return WillPopScope(
      onWillPop: () async {
        if (_activeView == ActiveView.schedule) {
          _handleBackToCalendar();
          return false;
        }
        return true;
      },
      child: Container(
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

              // ВАЖНО: растягиваем текущего и предыдущих детей на весь доступный размер
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },

              transitionBuilder: (child, anim) {
                final isCalendar = (child.key as ValueKey?)?.value == 'calendar';
                final offset = isCalendar ? const Offset(-0.05, 0) : const Offset(0.05, 0);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: offset, end: Offset.zero).animate(anim),
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
                onToggleExpanded: () => setState(() => _isExpanded = !_isExpanded),
                onToggleShowImportant: () =>
                    setState(() => _showOnlyImportant = !_showOnlyImportant),
              )
                  : DayScheduleView(
                key: const ValueKey('schedule'),
                selectedDate: _selectedDate,
                tasks: _getTasksForDate(_selectedDate),
                scrollToTaskId: _scrollToTaskId,
                onAddTask: (task) => _handleAddTask(task.copyWith(date: _selectedDate)),
                onUpdateTask: _handleUpdateTask,
                onDeleteTask: _handleDeleteTask,
                onBack: _handleBackToCalendar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
