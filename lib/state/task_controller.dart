import 'package:flutter/material.dart';

import '../data/task_storage.dart';
import '../models/task.dart';

class TaskController extends ChangeNotifier {
  TaskController._(this._storage, List<Task> tasks)
      : _tasks = tasks..sort(_byDateThenTime);

  final TaskStorage _storage;
  final List<Task> _tasks;

  static Future<TaskController> create() async {
    final TaskStorage storage = TaskStorage();
    final List<Task> tasks = await storage.loadTasks();
    return TaskController._(storage, tasks);
  }

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  List<Task> tasksForDate(DateTime date, {bool importantOnly = false}) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final Iterable<Task> filtered = _tasks.where((Task task) => task.date == normalized);
    final Iterable<Task> sorted = filtered.where((Task task) =>
        !importantOnly || (importantOnly && task.isImportant));
    final List<Task> result = sorted.toList()
      ..sort((Task a, Task b) => a.startMinutes.compareTo(b.startMinutes));
    return result;
  }

  Iterable<Task> importantTasksForMonth(DateTime month) {
    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final DateTime nextMonth = DateTime(month.year, month.month + 1, 1);
    return _tasks.where((Task task) =>
        task.isImportant && task.date.isAfter(firstDay.subtract(const Duration(days: 1))) && task.date.isBefore(nextMonth));
  }

  Task? findById(String id) {
    try {
      return _tasks.firstWhere((Task task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addOrUpdateTask(Task task) async {
    final int existingIndex = _tasks.indexWhere((Task element) => element.id == task.id);
    if (existingIndex == -1) {
      _tasks.add(task);
    } else {
      _tasks[existingIndex] = task;
    }
    _tasks.sort(_byDateThenTime);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((Task task) => task.id == taskId);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> toggleCompleted(String taskId) async {
    final int index = _tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) return;
    final Task task = _tasks[index];
    _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  static int _byDateThenTime(Task a, Task b) {
    final int dateComparison = a.date.compareTo(b.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return a.startMinutes.compareTo(b.startMinutes);
  }
}
