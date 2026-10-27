import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedWeekMondayProvider = StateProvider<DateTime>((ref) {
  return _mondayOf(DateTime.now());
});

final selectedDayIndexProvider = StateProvider<int>((ref) {
  return DateTime.now().weekday - 1; // 0 = Mon, 6 = Sun
});

final selectedDateProvider = Provider<DateTime>((ref) {
  final monday = ref.watch(selectedWeekMondayProvider);
  final dayIndex = ref.watch(selectedDayIndexProvider);
  return monday.add(Duration(days: dayIndex));
});

DateTime _mondayOf(DateTime date) {
  final offset = date.weekday - 1;
  return DateTime(date.year, date.month, date.day - offset);
}

DateTime mondayOfCurrentWeek() => _mondayOf(DateTime.now());
