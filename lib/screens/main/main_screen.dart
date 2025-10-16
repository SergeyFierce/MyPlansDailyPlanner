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
  DateTime _selectedDate = DateTime(2025, 10, 16);
  final DateTime _today = DateTime(2025, 10, 16);
  bool _showOnlyImportant = false;
  bool _isExpanded = false;
  int? _scrollToTaskId;

  final List<ScheduleTask> _scheduleTasks = [
    const ScheduleTask(
      id: 1,
      title: 'Встреча с клиентом',
      description: 'Обсудить детали проекта',
      startTime: '10:00',
      endTime: '11:30',
      isImportant: true,
      isCompleted: false,
      date: DateTime(2025, 10, 16),
    ),
    const ScheduleTask(
      id: 2,
      title: 'Работа над отчетом',
      startTime: '14:00',
      endTime: '16:00',
      isImportant: true,
      isCompleted: false,
      date: DateTime(2025, 10, 16),
    ),
    const ScheduleTask(
      id: 3,
      title: 'Спортзал',
      startTime: '18:00',
      endTime: '19:30',
      isImportant: false,
      isCompleted: true,
      date: DateTime(2025, 10, 16),
    ),
    const ScheduleTask(
      id: 4,
      title: 'Важная презентация',
      description: 'Подготовить материалы для презентации',
      startTime: '09:00',
      endTime: '10:30',
      isImportant: true,
      isCompleted: false,
      date: DateTime(2025, 10, 18),
    ),
  ];

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
          description: task.description,
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
                    onToggleShowImportant:
                        () => setState(() => _showOnlyImportant = !_showOnlyImportant),
                  )
                : DayScheduleView(
                    key: const ValueKey('schedule'),
                    selectedDate: _selectedDate,
                    tasks: _getTasksForDate(_selectedDate),
                    scrollToTaskId: _scrollToTaskId,
                    onAddTask: (task) => _handleAddTask(
                      task.copyWith(date: _selectedDate),
                    ),
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
