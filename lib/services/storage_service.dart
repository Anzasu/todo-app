import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_model.dart';
import '../models/weekly_task_model.dart';

class StorageService {
  static const _checklistsKey = 'checklists_v1';
  static const _weeklyTasksKey = 'weekly_tasks_v1';
  static const _themeKey = 'theme_index';
  static const _lastRolloverKey = 'last_rollover_date';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  List<ChecklistModel> loadChecklists() {
    final json = _prefs.getString(_checklistsKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((m) => ChecklistModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChecklists(List<ChecklistModel> checklists) async {
    await _prefs.setString(
        _checklistsKey, jsonEncode(checklists.map((c) => c.toMap()).toList()));
  }

  List<WeeklyTaskModel> loadWeeklyTasks() {
    final json = _prefs.getString(_weeklyTasksKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((m) => WeeklyTaskModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWeeklyTasks(List<WeeklyTaskModel> tasks) async {
    await _prefs.setString(
        _weeklyTasksKey, jsonEncode(tasks.map((t) => t.toMap()).toList()));
  }

  int loadThemeIndex() => _prefs.getInt(_themeKey) ?? 0;

  Future<void> saveThemeIndex(int index) async {
    await _prefs.setInt(_themeKey, index);
  }

  DateTime? loadLastRolloverDate() {
    final str = _prefs.getString(_lastRolloverKey);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> saveLastRolloverDate(DateTime date) async {
    await _prefs.setString(_lastRolloverKey, date.toIso8601String());
  }
}
