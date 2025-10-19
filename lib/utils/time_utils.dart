import 'package:flutter/material.dart';

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? parseTimeOfDay(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

int minutesFromTime(String value) {
  final time = parseTimeOfDay(value);
  if (time == null) return 0;
  return time.hour * 60 + time.minute;
}

TimeOfDay addMinutes(TimeOfDay time, int minutes) {
  final totalMinutes = time.hour * 60 + time.minute + minutes;
  final clampedMinutes = totalMinutes.clamp(0, 23 * 60 + 59) as int;
  final hour = clampedMinutes ~/ 60;
  final minute = clampedMinutes % 60;
  return TimeOfDay(hour: hour, minute: minute);
}

bool isEndAfterStart(TimeOfDay start, TimeOfDay end) {
  if (end.hour > start.hour) return true;
  if (end.hour == start.hour && end.minute > start.minute) return true;
  return false;
}

String formatTimeLabel(String start, String end) {
  if (start == end) {
    return start;
  }
  return '$start – $end';
}
