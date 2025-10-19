class SubTask {
  final int id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Task {
  final int id;
  final String title;
  final DateTime date;
  final bool isImportant;
  final bool isCompleted;
  final List<SubTask> subTasks;

  const Task({
    required this.id,
    required this.title,
    required this.date,
    this.isImportant = false,
    this.isCompleted = false,
    this.subTasks = const [],
  });

  Task copyWith({
    String? title,
    DateTime? date,
    bool? isImportant,
    bool? isCompleted,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}

class ScheduleTask extends Task {
  final String startTime;
  final String endTime;

  const ScheduleTask({
    required int id,
    required String title,
    required DateTime date,
    required this.startTime,
    required this.endTime,
    bool isImportant = false,
    bool isCompleted = false,
    List<SubTask> subTasks = const [],
  }) : super(
          id: id,
          title: title,
          date: date,
          isImportant: isImportant,
          isCompleted: isCompleted,
          subTasks: subTasks,
        );

  bool get hasDuration => startTime != endTime;

  @override
  ScheduleTask copyWith({
    String? title,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isImportant,
    bool? isCompleted,
    List<SubTask>? subTasks,
  }) {
    final updatedSubTasks = subTasks ?? this.subTasks;
    return ScheduleTask(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: updatedSubTasks,
    );
  }
}
