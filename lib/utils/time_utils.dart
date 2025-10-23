import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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

TimeOfDay timeOfDayFromDateTime(DateTime dateTime) {
  return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
}

DateTime combineDateAndTime({
  required DateTime date,
  required TimeOfDay time,
  bool toUtc = false,
}) {
  final combined = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  return toUtc ? combined.toUtc() : combined;
}

String formatTimeRange(DateTime startLocal, DateTime endLocal) {
  final formatter = DateFormat('HH:mm');
  final startLabel = formatter.format(startLocal);
  final endLabel = formatter.format(endLocal);
  if (startLabel == endLabel) {
    return startLabel;
  }
  return '$startLabel – $endLabel';
}
