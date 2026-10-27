
import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

enum NotificationTiming { sameDay, oneDayBefore, twoDaysBefore }

extension TaskPriorityLabel on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Niedrig',
        TaskPriority.medium => 'Mittel',
        TaskPriority.high => 'Hoch',
      };
}

extension NotificationTimingLabel on NotificationTiming {
  String get label => switch (this) {
        NotificationTiming.sameDay => 'Am selben Tag',
        NotificationTiming.oneDayBefore => '1 Tag vorher',
        NotificationTiming.twoDaysBefore => '2 Tage vorher',
      };
}

class WeeklyTaskModel {
  final String id;
  final String description;
  final DateTime assignedDate;
  final DateTime? deadline;
  final TaskPriority priority;
  final bool isCompleted;
  final bool isMissed;
  final List<NotificationTiming> notifications;
  final int sortOrder;

  WeeklyTaskModel({
    required this.id,
    required this.description,
    required DateTime assignedDate,
    DateTime? deadline,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.isMissed = false,
    List<NotificationTiming> notifications = const [],
    this.sortOrder = 0,
  })  : assignedDate = _dateOnly(assignedDate),
        deadline = deadline == null ? null : _dateOnly(deadline),
        notifications = List.unmodifiable(notifications);

  factory WeeklyTaskModel.create({
    required String description,
    required DateTime assignedDate,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.medium,
    List<NotificationTiming> notifications = const [],
    int sortOrder = 0,
  }) {
    return WeeklyTaskModel(
      id: const Uuid().v4(),
      description: description,
      assignedDate: assignedDate,
      deadline: deadline,
      priority: priority,
      notifications: notifications,
      sortOrder: sortOrder,
    );
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  WeeklyTaskModel copyWith({
    String? description,
    DateTime? assignedDate,
    Object? deadline = _sentinel,
    TaskPriority? priority,
    bool? isCompleted,
    bool? isMissed,
    List<NotificationTiming>? notifications,
    int? sortOrder,
  }) {
    return WeeklyTaskModel(
      id: id,
      description: description ?? this.description,
      assignedDate: assignedDate ?? this.assignedDate,
      deadline: identical(deadline, _sentinel)
          ? this.deadline
          : deadline as DateTime?,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isMissed: isMissed ?? this.isMissed,
      notifications: notifications ?? this.notifications,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'assignedDate': assignedDate.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'priority': priority.index,
        'isCompleted': isCompleted,
        'isMissed': isMissed,
        'notifications': notifications.map((n) => n.index).toList(),
        'sortOrder': sortOrder,
      };

  factory WeeklyTaskModel.fromMap(Map<String, dynamic> map) {
    final rawNotifications = map['notifications'];

    return WeeklyTaskModel(
      id: map['id'] as String,
      description: map['description'] as String,
      assignedDate: _parseDate(map['assignedDate']),
      deadline: map['deadline'] == null
          ? null
          : _parseDate(map['deadline']),
      priority: _enumValueOrDefault(
        TaskPriority.values,
        map['priority'],
        TaskPriority.medium,
      ),
      isCompleted: map['isCompleted'] as bool? ?? false,
      isMissed: map['isMissed'] as bool? ?? false,
      notifications: rawNotifications is List
          ? rawNotifications
              .whereType<int>()
              .where(
                (index) =>
                    index >= 0 &&
                    index < NotificationTiming.values.length,
              )
              .map((index) => NotificationTiming.values[index])
              .toList()
          : const [],
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is String) {
      return _dateOnly(DateTime.parse(value));
    }

    throw const FormatException(
      'Invalid or missing date in saved weekly task.',
    );
  }

  static T _enumValueOrDefault<T>(
    List<T> values,
    Object? index,
    T fallback,
  ) {
    if (index is int && index >= 0 && index < values.length) {
      return values[index];
    }
    return fallback;
  }
}

const _sentinel = Object();
