class SubTask {
  final int id;
  final String title;
  final bool isCompleted;
  final String comment;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.comment = '',
  });

  SubTask copyWith({
    String? title,
    bool? isCompleted,
    String? comment,
  }) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      comment: comment ?? this.comment,
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
  final String comment;

  const Task({
    required this.id,
    required this.title,
    required this.date,
    this.isImportant = false,
    this.isCompleted = false,
    this.subTasks = const [],
    this.comment = '',
  });

  Task copyWith({
    String? title,
    DateTime? date,
    bool? isImportant,
    bool? isCompleted,
    List<SubTask>? subTasks,
    String? comment,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      comment: comment ?? this.comment,
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
    String comment = '',
  }) : super(
          id: id,
          title: title,
          date: date,
          isImportant: isImportant,
          isCompleted: isCompleted,
          subTasks: subTasks,
          comment: comment,
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
    String? comment,
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
      comment: comment ?? this.comment,
    );
  }
}
