import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../models/task.dart';
import '../../../utils/astronomy.dart';
import '../models/day_schedule_models.dart';

class DayScheduleController extends ChangeNotifier {
  DayScheduleController({
    required this.selectedDate,
    required List<ScheduleTask> initialTasks,
  }) : _tasks = List<ScheduleTask>.from(initialTasks) {
    _location = tz.getLocation('UTC');
    _state = DayScheduleState.initial(
      selectedDate: selectedDate,
      location: _location,
    );
  }

  final DateTime selectedDate;
  final SunriseSunsetCalculator _astronomy = const SunriseSunsetCalculator();

  late DayScheduleState _state;
  late tz.Location _location;
  List<ScheduleTask> _tasks;
  Position? _currentPosition;
  Timer? _ticker;
  StreamSubscription<Position>? _positionSubscription;
  bool _isDisposed = false;

  static bool _timezoneInitialized = false;

  DayScheduleState get state => _state;
  tz.Location get location => _location;

  Future<void> initialize() async {
    await _ensureTimezoneData();
    await _resolveTimezone(force: true);
    await _resolveLocation(forceRequest: true);
    _updateNow();
    _rebuildState();
    _startTicker();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void updateTasks(List<ScheduleTask> tasks) {
    _tasks = List<ScheduleTask>.from(tasks);
    _rebuildState();
  }

  Future<void> refreshEnvironment() async {
    await _resolveTimezone(force: false);
    await _resolveLocation(forceRequest: false);
    _updateNow();
    _rebuildState();
  }

  Future<void> _ensureTimezoneData() async {
    if (_timezoneInitialized) {
      return;
    }
    tzdata.initializeTimeZones();
    _timezoneInitialized = true;
  }

  Future<void> _resolveTimezone({required bool force}) async {
    try {
      final timezoneName = await FlutterNativeTimezone.getLocalTimezone();
      if (!force && timezoneName == _state.timezoneName) {
        return;
      }
      tz.Location location;
      try {
        location = tz.getLocation(timezoneName);
      } catch (_) {
        location = tz.getLocation('UTC');
      }
      _location = location;
      _state = _state.copyWith(
        timezoneName: location.name,
        timezoneResolved: true,
        now: tz.TZDateTime.from(DateTime.now().toUtc(), _location),
      );
    } catch (error) {
      _state = _state.copyWith(
        timezoneResolved: false,
        errorMessage: 'Не удалось определить часовой пояс',
      );
    }
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _resolveLocation({required bool forceRequest}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentPosition = null;
      _state = _state.copyWith(
        locationServiceDisabled: true,
        locationResolved: false,
      );
      _cancelPositionStream();
      if (!_isDisposed) notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && forceRequest) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _state = _state.copyWith(
        locationPermissionDenied: true,
        locationPermissionPermanentlyDenied: false,
        locationResolved: false,
        locationServiceDisabled: false,
      );
      _currentPosition = null;
      _cancelPositionStream();
      if (!_isDisposed) notifyListeners();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _state = _state.copyWith(
        locationPermissionDenied: false,
        locationPermissionPermanentlyDenied: true,
        locationResolved: false,
        locationServiceDisabled: false,
      );
      _currentPosition = null;
      _cancelPositionStream();
      if (!_isDisposed) notifyListeners();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _currentPosition = position;
      _state = _state.copyWith(
        locationResolved: true,
        locationPermissionDenied: false,
        locationPermissionPermanentlyDenied: false,
        locationServiceDisabled: false,
        errorMessage: null,
        resetError: true,
      );
      _subscribeToLocationUpdates();
    } catch (error) {
      _state = _state.copyWith(
        locationResolved: false,
        errorMessage: 'Не удалось определить местоположение',
      );
    }

    if (!_isDisposed) notifyListeners();
  }

  void _subscribeToLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 250,
      ),
    ).listen((position) {
      _currentPosition = position;
      _rebuildState();
    });
  }

  void _cancelPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _onTick();
    });
  }

  Future<void> _onTick() async {
    await _resolveTimezone(force: false);
    _updateNow();
    _rebuildState();
  }

  void _updateNow() {
    _state = _state.copyWith(
      now: tz.TZDateTime.from(DateTime.now().toUtc(), _location),
    );
  }

  void _rebuildState() {
    final location = _location;
    final now = tz.TZDateTime.from(DateTime.now().toUtc(), location);
    final selectedDayStart = tz.TZDateTime(location, selectedDate.year,
        selectedDate.month, selectedDate.day);
    final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

    final localTasks = _tasks
        .map((task) {
          final startLocal = tz.TZDateTime.from(task.startUtc, location);
          final endLocal = tz.TZDateTime.from(task.endUtc, location);
          return _LocalTask(
            task: task,
            start: startLocal,
            end: endLocal.isBefore(startLocal)
                ? startLocal.add(const Duration(minutes: 30))
                : endLocal,
          );
        })
        .where(
          (entry) =>
              !entry.end.isBefore(selectedDayStart) &&
              entry.start.isBefore(selectedDayEnd),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final progress = DayProgress(
      total: localTasks.length,
      completed: localTasks.where((item) => item.task.isCompleted).length,
      important: localTasks.where((item) => item.task.isImportant).length,
    );

    final solarTimes = _buildSolarTimes(location: location);
    final segments = _buildSegments(
      tasks: localTasks,
      solarTimes: solarTimes,
      now: now,
    );

    SegmentedTask? currentTask;
    for (final segment in segments) {
      for (final task in segment.tasks) {
        if (task.isCurrent) {
          currentTask = task;
          break;
        }
      }
      if (currentTask != null) {
        break;
      }
    }

    final celebration =
        progress.total > 0 && progress.completed == progress.total;

    _state = _state.copyWith(
      now: now,
      isLoading: false,
      progress: progress,
      segments: segments,
      solarTimes: solarTimes,
      currentTask: currentTask,
      celebrationUnlocked: celebration,
      locationResolved: _state.locationResolved || _currentPosition != null,
    );

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  SolarTimes _buildSolarTimes({required tz.Location location}) {
    final day = DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
    tz.TZDateTime sunriseLocal;
    tz.TZDateTime sunsetLocal;
    tz.TZDateTime solarNoonLocal;

    if (_currentPosition != null) {
      final result = _astronomy.calculate(
        date: day,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      sunriseLocal = result.sunriseUtc != null
          ? tz.TZDateTime.from(result.sunriseUtc!, location)
          : tz.TZDateTime(location, selectedDate.year, selectedDate.month,
              selectedDate.day, 6);
      sunsetLocal = result.sunsetUtc != null
          ? tz.TZDateTime.from(result.sunsetUtc!, location)
          : tz.TZDateTime(location, selectedDate.year, selectedDate.month,
              selectedDate.day, 20);
      solarNoonLocal = result.solarNoonUtc != null
          ? tz.TZDateTime.from(result.solarNoonUtc!, location)
          : tz.TZDateTime(location, selectedDate.year, selectedDate.month,
              selectedDate.day, 13);
    } else {
      sunriseLocal = tz.TZDateTime(location, selectedDate.year,
          selectedDate.month, selectedDate.day, 6);
      solarNoonLocal = tz.TZDateTime(location, selectedDate.year,
          selectedDate.month, selectedDate.day, 13);
      sunsetLocal = tz.TZDateTime(location, selectedDate.year,
          selectedDate.month, selectedDate.day, 20);
    }

    if (!sunriseLocal.isBefore(solarNoonLocal)) {
      solarNoonLocal = sunriseLocal.add(const Duration(hours: 4));
    }
    if (!solarNoonLocal.isBefore(sunsetLocal)) {
      sunsetLocal = solarNoonLocal.add(const Duration(hours: 4));
    }

    var nightStart = tz.TZDateTime(location, selectedDate.year,
        selectedDate.month, selectedDate.day, 22);
    if (!sunsetLocal.isBefore(nightStart)) {
      nightStart = sunsetLocal.add(const Duration(hours: 1));
    }
    if (nightStart.hour >= 24) {
      nightStart = tz.TZDateTime(location, selectedDate.year,
          selectedDate.month, selectedDate.day, 23, 30);
    }

    tz.TZDateTime nextSunrise;
    if (_currentPosition != null) {
      final nextResult = _astronomy.calculate(
        date: day.add(const Duration(days: 1)),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      nextSunrise = nextResult.sunriseUtc != null
          ? tz.TZDateTime.from(nextResult.sunriseUtc!, location)
          : nightStart.add(const Duration(hours: 7));
    } else {
      nextSunrise = nightStart.add(const Duration(hours: 8));
    }

    if (!nightStart.isBefore(nextSunrise)) {
      nextSunrise = nightStart.add(const Duration(hours: 6));
    }

    return SolarTimes(
      sunrise: sunriseLocal,
      solarNoon: solarNoonLocal,
      sunset: sunsetLocal,
      nightStart: nightStart,
      nextSunrise: nextSunrise,
    );
  }

  List<DaySegment> _buildSegments({
    required List<_LocalTask> tasks,
    required SolarTimes solarTimes,
    required tz.TZDateTime now,
  }) {
    final segments = <DaySegmentType, List<SegmentedTask>>{
      DaySegmentType.morning: [],
      DaySegmentType.day: [],
      DaySegmentType.evening: [],
      DaySegmentType.night: [],
    };

    for (final entry in tasks) {
      final isCurrent = _isCurrentTask(entry: entry, now: now);
      final type = _segmentForTask(entry: entry, solarTimes: solarTimes);
      segments[type]!.add(
        SegmentedTask(
          task: entry.task,
          start: entry.start,
          end: entry.end,
          isCurrent: isCurrent,
        ),
      );
    }

    DaySegment buildSegment({
      required DaySegmentType type,
      required String title,
      required String emoji,
      required tz.TZDateTime start,
      required tz.TZDateTime end,
    }) {
      final tasks = segments[type]!
        ..sort((a, b) => a.start.compareTo(b.start));
      return DaySegment(
        type: type,
        title: title,
        emoji: emoji,
        start: start,
        end: end,
        tasks: List<SegmentedTask>.from(tasks),
      );
    }

    final dayStart = tz.TZDateTime(
      _location,
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return [
      buildSegment(
        type: DaySegmentType.morning,
        title: 'Утро',
        emoji: '🌅',
        start: solarTimes.sunrise.isBefore(dayStart)
            ? dayStart
            : solarTimes.sunrise,
        end: solarTimes.solarNoon,
      ),
      buildSegment(
        type: DaySegmentType.day,
        title: 'День',
        emoji: '☀️',
        start: solarTimes.solarNoon,
        end: solarTimes.sunset,
      ),
      buildSegment(
        type: DaySegmentType.evening,
        title: 'Вечер',
        emoji: '🌆',
        start: solarTimes.sunset,
        end: solarTimes.nightStart,
      ),
      buildSegment(
        type: DaySegmentType.night,
        title: 'Ночь',
        emoji: '🌙',
        start: solarTimes.nightStart,
        end: solarTimes.nextSunrise,
      ),
    ];
  }

  DaySegmentType _segmentForTask({
    required _LocalTask entry,
    required SolarTimes solarTimes,
  }) {
    final start = entry.start;
    if (start.isBefore(solarTimes.sunrise)) {
      return DaySegmentType.night;
    }
    if (start.isBefore(solarTimes.solarNoon)) {
      return DaySegmentType.morning;
    }
    if (start.isBefore(solarTimes.sunset)) {
      return DaySegmentType.day;
    }
    if (start.isBefore(solarTimes.nightStart)) {
      return DaySegmentType.evening;
    }
    return DaySegmentType.night;
  }

  bool _isCurrentTask({
    required _LocalTask entry,
    required tz.TZDateTime now,
  }) {
    if (entry.task.isCompleted) {
      return false;
    }
    if (entry.task.hasDuration) {
      final startsBeforeNow = !entry.start.isAfter(now);
      final endsAfterNow = entry.end.isAfter(now);
      return startsBeforeNow && endsAfterNow;
    }
    final difference = entry.start.difference(now).inMinutes.abs();
    return difference < 5;
  }
}

class _LocalTask {
  const _LocalTask({
    required this.task,
    required this.start,
    required this.end,
  });

  final ScheduleTask task;
  final tz.TZDateTime start;
  final tz.TZDateTime end;
}
