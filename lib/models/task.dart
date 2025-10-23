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

enum TaskCategory {
  work,
  personal,
  health,
  learning,
}

class ScheduleTask extends Task {
  final DateTime startUtc;
  final DateTime endUtc;
  final TaskCategory category;
  final bool hasReminder;

  ScheduleTask({
    required int id,
    required String title,
    required DateTime date,
    required this.startUtc,
    required this.endUtc,
    this.category = TaskCategory.work,
    bool isImportant = false,
    bool isCompleted = false,
    this.hasReminder = false,
    List<SubTask> subTasks = const [],
    String comment = '',
  })  : assert(startUtc.isUtc, 'startUtc must be stored in UTC'),
        assert(endUtc.isUtc, 'endUtc must be stored in UTC'),
        super(
          id: id,
          title: title,
          date: date,
          isImportant: isImportant,
          isCompleted: isCompleted,
          subTasks: subTasks,
          comment: comment,
        );

  bool get hasDuration => !startUtc.isAtSameMomentAs(endUtc);

  Duration get effectiveDuration => endUtc.difference(startUtc);

  @override
  ScheduleTask copyWith({
    String? title,
    DateTime? date,
    DateTime? startUtc,
    DateTime? endUtc,
    bool? isImportant,
    bool? isCompleted,
    List<SubTask>? subTasks,
    String? comment,
    TaskCategory? category,
    bool? hasReminder,
  }) {
    final updatedSubTasks = subTasks ?? this.subTasks;
    return ScheduleTask(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: updatedSubTasks,
      comment: comment ?? this.comment,
      category: category ?? this.category,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }
}
