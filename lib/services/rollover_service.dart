import '../models/weekly_task_model.dart';

class RolloverService {
  /// Performs rollover for all unprocessed days up to (but not including) today.
  /// Incomplete tasks on each day get marked as missed and a copy is created for the next day.
  List<WeeklyTaskModel> performRollover({
    required List<WeeklyTaskModel> tasks,
    required DateTime? lastRolloverDate,
    required DateTime today,
  }) {
    final todayDate = _dateOnly(today);

    if (lastRolloverDate == null) {
      return tasks;
    }

    final lastDate = _dateOnly(lastRolloverDate);
    if (!lastDate.isBefore(todayDate)) {
      return tasks;
    }

    final result = List<WeeklyTaskModel>.from(tasks);
    var current = lastDate;

    while (current.isBefore(todayDate)) {
      final next = current.add(const Duration(days: 1));
      final incomplete = result
          .where((t) =>
              _dateOnly(t.assignedDate) == current &&
              !t.isCompleted &&
              !t.isMissed)
          .toList();

      for (final task in incomplete) {
        final idx = result.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          result[idx] = task.copyWith(isMissed: true);
        }
        result.add(WeeklyTaskModel.create(
          description: task.description,
          assignedDate: next,
          deadline: task.deadline,
          priority: task.priority,
          notifications: List<NotificationTiming>.from(task.notifications),
          sortOrder: task.sortOrder,
        ));
      }
      current = next;
    }

    return result;
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
