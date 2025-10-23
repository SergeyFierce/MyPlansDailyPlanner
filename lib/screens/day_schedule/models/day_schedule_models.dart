import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../models/task.dart';

enum DaySegmentType { morning, day, evening, night }

@immutable
class SolarTimes {
  const SolarTimes({
    required this.sunrise,
    required this.solarNoon,
    required this.sunset,
    required this.nightStart,
    required this.nextSunrise,
  });

  final tz.TZDateTime sunrise;
  final tz.TZDateTime solarNoon;
  final tz.TZDateTime sunset;
  final tz.TZDateTime nightStart;
  final tz.TZDateTime nextSunrise;
}

@immutable
class SegmentedTask {
  const SegmentedTask({
    required this.task,
    required this.start,
    required this.end,
    required this.isCurrent,
  });

  final ScheduleTask task;
  final tz.TZDateTime start;
  final tz.TZDateTime end;
  final bool isCurrent;

  bool get isCompleted => task.isCompleted;
  bool get isImportant => task.isImportant;
  bool get hasReminder => task.hasReminder;
  TaskCategory get category => task.category;
}

@immutable
class DaySegment {
  const DaySegment({
    required this.type,
    required this.title,
    required this.emoji,
    required this.start,
    required this.end,
    required this.tasks,
  });

  final DaySegmentType type;
  final String title;
  final String emoji;
  final tz.TZDateTime start;
  final tz.TZDateTime end;
  final List<SegmentedTask> tasks;

  bool get isEmpty => tasks.isEmpty;
}

@immutable
class DayProgress {
  const DayProgress({
    required this.total,
    required this.completed,
    required this.important,
  });

  final int total;
  final int completed;
  final int important;

  double get completionRate => total == 0 ? 0 : completed / total;
}

@immutable
class DayScheduleState {
  const DayScheduleState({
    required this.selectedDate,
    required this.now,
    required this.timezoneName,
    required this.locationResolved,
    required this.timezoneResolved,
    required this.locationPermissionDenied,
    required this.locationPermissionPermanentlyDenied,
    required this.locationServiceDisabled,
    required this.isLoading,
    required this.segments,
    required this.progress,
    this.currentTask,
    this.solarTimes,
    this.errorMessage,
    this.celebrationUnlocked = false,
  });

  final DateTime selectedDate;
  final tz.TZDateTime now;
  final String timezoneName;
  final bool locationResolved;
  final bool timezoneResolved;
  final bool locationPermissionDenied;
  final bool locationPermissionPermanentlyDenied;
  final bool locationServiceDisabled;
  final bool isLoading;
  final List<DaySegment> segments;
  final DayProgress progress;
  final SegmentedTask? currentTask;
  final SolarTimes? solarTimes;
  final String? errorMessage;
  final bool celebrationUnlocked;

  DayScheduleState copyWith({
    tz.TZDateTime? now,
    String? timezoneName,
    bool? locationResolved,
    bool? timezoneResolved,
    bool? locationPermissionDenied,
    bool? locationPermissionPermanentlyDenied,
    bool? locationServiceDisabled,
    bool? isLoading,
    List<DaySegment>? segments,
    DayProgress? progress,
    SegmentedTask? currentTask,
    SolarTimes? solarTimes,
    String? errorMessage,
    bool? celebrationUnlocked,
    bool resetError = false,
  }) {
    return DayScheduleState(
      selectedDate: selectedDate,
      now: now ?? this.now,
      timezoneName: timezoneName ?? this.timezoneName,
      locationResolved: locationResolved ?? this.locationResolved,
      timezoneResolved: timezoneResolved ?? this.timezoneResolved,
      locationPermissionDenied:
          locationPermissionDenied ?? this.locationPermissionDenied,
      locationPermissionPermanentlyDenied:
          locationPermissionPermanentlyDenied ??
              this.locationPermissionPermanentlyDenied,
      locationServiceDisabled:
          locationServiceDisabled ?? this.locationServiceDisabled,
      isLoading: isLoading ?? this.isLoading,
      segments: segments ?? this.segments,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      solarTimes: solarTimes ?? this.solarTimes,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      celebrationUnlocked:
          celebrationUnlocked ?? this.celebrationUnlocked,
    );
  }

  factory DayScheduleState.initial({
    required DateTime selectedDate,
    required tz.Location location,
  }) {
    final now = tz.TZDateTime.from(DateTime.now().toUtc(), location);
    return DayScheduleState(
      selectedDate: selectedDate,
      now: now,
      timezoneName: location.name,
      locationResolved: false,
      timezoneResolved: true,
      locationPermissionDenied: false,
      locationPermissionPermanentlyDenied: false,
      locationServiceDisabled: false,
      isLoading: true,
      segments: const [],
      progress: const DayProgress(total: 0, completed: 0, important: 0),
    );
  }
}
