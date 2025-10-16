import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

class Task {
  Task({
    required this.id,
    required DateTime date,
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
    this.description = '',
    this.isImportant = false,
    this.isCompleted = false,
  }) : date = DateTime(date.year, date.month, date.day);

  factory Task.create({
    required DateTime date,
    required String title,
    required int startMinutes,
    required int endMinutes,
    String description = '',
    bool isImportant = false,
  }) {
    return Task(
      id: _uuid.v4(),
      date: date,
      title: title,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      description: description,
      isImportant: isImportant,
      isCompleted: false,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
      description: json['description'] as String? ?? '',
      isImportant: json['isImportant'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  final String id;
  final DateTime date;
  final String title;
  final int startMinutes;
  final int endMinutes;
  final String description;
  final bool isImportant;
  final bool isCompleted;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'description': description,
        'isImportant': isImportant,
        'isCompleted': isCompleted,
      };

  Task copyWith({
    String? id,
    DateTime? date,
    String? title,
    int? startMinutes,
    int? endMinutes,
    String? description,
    bool? isImportant,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      description: description ?? this.description,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool overlaps(Task other) {
    if (date != other.date) return false;
    return startMinutes < other.endMinutes && other.startMinutes < endMinutes;
  }

  TimeOfDay get startTimeOfDay => _minutesToTimeOfDay(startMinutes);

  TimeOfDay get endTimeOfDay => _minutesToTimeOfDay(endMinutes);

  static TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static int minutesFromTimeOfDay(TimeOfDay timeOfDay) {
    return timeOfDay.hour * 60 + timeOfDay.minute;
  }
}
