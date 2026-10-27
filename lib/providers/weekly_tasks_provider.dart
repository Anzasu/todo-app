import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_task_model.dart';
import '../services/storage_service.dart';
import '../services/rollover_service.dart';
import '../services/notification_service.dart';
import 'storage_provider.dart';

final weeklyTasksProvider =
    StateNotifierProvider<WeeklyTasksNotifier, List<WeeklyTaskModel>>((ref) {
  return WeeklyTasksNotifier(
    ref.read(storageServiceProvider),
    ref.read(rolloverServiceProvider),
  );
});

class WeeklyTasksNotifier extends StateNotifier<List<WeeklyTaskModel>> {
  final StorageService _storage;
  final RolloverService _rollover;

  WeeklyTasksNotifier(this._storage, this._rollover) : super([]) {
    _init();
  }

  Future<void> _init() async {
    var tasks = _storage.loadWeeklyTasks();
    final lastRollover = _storage.loadLastRolloverDate();
    final today = DateTime.now();
    tasks = _rollover.performRollover(
      tasks: tasks,
      lastRolloverDate: lastRollover,
      today: today,
    );
    await _storage.saveLastRolloverDate(today);
    await _storage.saveWeeklyTasks(tasks);
    state = tasks;
  }

  List<WeeklyTaskModel> getTasksForDate(DateTime date) {
    final d = _dateOnly(date);
    final tasks = state
        .where((t) => _dateOnly(t.assignedDate) == d)
        .toList();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tasks;
  }

  Future<void> addTask(WeeklyTaskModel task) async {
    final existing = getTasksForDate(task.assignedDate);
    final baseOrder = switch (task.priority) {
      TaskPriority.high => 0,
      TaskPriority.medium => 1000,
      TaskPriority.low => 2000,
    };
    final withOrder = task.copyWith(sortOrder: baseOrder + existing.length);
    state = [...state, withOrder];
    await _storage.saveWeeklyTasks(state);
    await NotificationService().scheduleTaskNotifications(withOrder);
  }

  Future<void> updateTask(WeeklyTaskModel updated) async {
    await NotificationService().cancelTaskNotifications(updated.id);
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
    await _storage.saveWeeklyTasks(state);
    await NotificationService().scheduleTaskNotifications(updated);
  }

  Future<void> toggleTask(String id) async {
    state = state
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList();
    await _storage.saveWeeklyTasks(state);
  }

  Future<void> deleteTask(String id) async {
    await NotificationService().cancelTaskNotifications(id);
    state = state.where((t) => t.id != id).toList();
    await _storage.saveWeeklyTasks(state);
  }

  Future<void> reorderTasks(DateTime date, int oldIndex, int newIndex) async {
    final dateTasks = getTasksForDate(date);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = dateTasks.removeAt(oldIndex);
    dateTasks.insert(newIndex, moved);

    final updated = List<WeeklyTaskModel>.from(state);
    for (var i = 0; i < dateTasks.length; i++) {
      final idx = updated.indexWhere((t) => t.id == dateTasks[i].id);
      if (idx != -1) {
        updated[idx] = updated[idx].copyWith(sortOrder: i * 10);
      }
    }
    state = updated;
    await _storage.saveWeeklyTasks(state);
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
