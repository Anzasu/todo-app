import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/weekly_tasks_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/weekly_task_model.dart';
import '../widgets/weekly_task_tile.dart';
import 'weekly_task_form.dart';

class WochenplanScreen extends ConsumerStatefulWidget {
  const WochenplanScreen({super.key});

  @override
  ConsumerState<WochenplanScreen> createState() => _WochenplanScreenState();
}

class _WochenplanScreenState extends ConsumerState<WochenplanScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final dayIndex = ref.read(selectedDayIndexProvider);
    _pageController = PageController(initialPage: dayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime get _currentWeekMonday => ref.read(selectedWeekMondayProvider);
  DateTime get _minWeekMonday => mondayOfCurrentWeek();

  bool get _canGoToPrevDay {
    final dayIndex = ref.read(selectedDayIndexProvider);
    if (dayIndex > 0) return true;
    return _currentWeekMonday.isAfter(_minWeekMonday);
  }

  void _goToPrevDay() {
    final dayIndex = ref.read(selectedDayIndexProvider);
    if (dayIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentWeekMonday.isAfter(_minWeekMonday)) {
      _changeWeek(_currentWeekMonday.subtract(const Duration(days: 7)), 6);
    }
  }

  void _goToNextDay() {
    final dayIndex = ref.read(selectedDayIndexProvider);
    if (dayIndex < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _changeWeek(_currentWeekMonday.add(const Duration(days: 7)), 0);
    }
  }

  void _changeWeek(DateTime newMonday, int newDayIndex) {
    ref.read(selectedWeekMondayProvider.notifier).state = newMonday;
    ref.read(selectedDayIndexProvider.notifier).state = newDayIndex;
    _pageController.dispose();
    _pageController = PageController(initialPage: newDayIndex);
    setState(() {});
  }

  void _goToPrevWeek() {
    if (_currentWeekMonday.isAfter(_minWeekMonday)) {
      _changeWeek(_currentWeekMonday.subtract(const Duration(days: 7)), 0);
    }
  }

  void _goToNextWeek() {
    _changeWeek(_currentWeekMonday.add(const Duration(days: 7)), 0);
  }

  @override
  Widget build(BuildContext context) {
    final weekMonday = ref.watch(selectedWeekMondayProvider);
    final dayIndex = ref.watch(selectedDayIndexProvider);
    final selectedDate = weekMonday.add(Duration(days: dayIndex));
    final isCurrentWeek = _dateOnly(weekMonday) == _dateOnly(_minWeekMonday);
    final canPrevWeek = !isCurrentWeek;

    return Column(
      children: [
        _WeekHeader(
          weekMonday: weekMonday,
          canPrevWeek: canPrevWeek,
          onPrevWeek: _goToPrevWeek,
          onNextWeek: _goToNextWeek,
        ),
        _DayStrip(
          weekMonday: weekMonday,
          selectedIndex: dayIndex,
          onDayTap: (i) {
            ref.read(selectedDayIndexProvider.notifier).state = i;
            _pageController.animateToPage(i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
        ),
        _DayNavRow(
          selectedDate: selectedDate,
          canGoPrev: _canGoToPrevDay,
          onPrev: _goToPrevDay,
          onNext: _goToNextDay,
        ),
        const Divider(height: 1),
        Expanded(
          child: PageView.builder(
            key: ValueKey(weekMonday.toIso8601String()),
            controller: _pageController,
            itemCount: 7,
            onPageChanged: (i) {
              ref.read(selectedDayIndexProvider.notifier).state = i;
            },
            itemBuilder: (context, i) {
              final day = weekMonday.add(Duration(days: i));
              return _DayPage(date: day);
            },
          ),
        ),
      ],
    );
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

class _WeekHeader extends StatelessWidget {
  final DateTime weekMonday;
  final bool canPrevWeek;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const _WeekHeader({
    required this.weekMonday,
    required this.canPrevWeek,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final sunday = weekMonday.add(const Duration(days: 6));
    final weekNum = _isoWeekNumber(weekMonday);
    final range =
        '${DateFormat('dd.MM').format(weekMonday)} – ${DateFormat('dd.MM.yy').format(sunday)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canPrevWeek ? onPrevWeek : null,
            tooltip: 'Vorherige Woche',
          ),
          Expanded(
            child: Column(
              children: [
                Text('KW $weekNum',
                    style: Theme.of(context).textTheme.titleSmall),
                Text(range,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextWeek,
            tooltip: 'Nächste Woche',
          ),
        ],
      ),
    );
  }

  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 3 - (date.weekday - 1)));
    final firstThursday = DateTime(thursday.year, 1, 1)
        .add(Duration(days: (4 - DateTime(thursday.year, 1, 1).weekday + 7) % 7));
    return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
  }
}

class _DayStrip extends StatelessWidget {
  final DateTime weekMonday;
  final int selectedIndex;
  final void Function(int) onDayTap;

  const _DayStrip({
    required this.weekMonday,
    required this.selectedIndex,
    required this.onDayTap,
  });

  static const _dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: Row(
        children: List.generate(7, (i) {
          final day = weekMonday.add(Duration(days: i));
          final isSelected = i == selectedIndex;
          final isToday = _isSameDay(day, today);

          return Expanded(
            child: GestureDetector(
              onTap: () => onDayTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(color: colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayNames[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayNavRow extends StatelessWidget {
  final DateTime selectedDate;
  final bool canGoPrev;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _fullDayNames = [
    'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
    'Freitag', 'Samstag', 'Sonntag'
  ];

  const _DayNavRow({
    required this.selectedDate,
    required this.canGoPrev,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = _fullDayNames[selectedDate.weekday - 1];
    final dateStr = DateFormat('dd. MMMM yyyy', 'de_DE').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: canGoPrev ? onPrev : null,
            tooltip: 'Vorheriger Tag',
          ),
          Expanded(
            child: Column(
              children: [
                Text(dayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(dateStr,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: onNext,
            tooltip: 'Nächster Tag',
          ),
        ],
      ),
    );
  }
}

class _DayPage extends ConsumerWidget {
  final DateTime date;

  const _DayPage({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(weeklyTasksProvider); // trigger rebuild on state change
    final notifier = ref.read(weeklyTasksProvider.notifier);
    final tasks = notifier.getTasksForDate(date);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available,
                size: 72,
                color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Keine Aufgaben',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um eine Aufgabe hinzuzufügen',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) {
        notifier.reorderTasks(date, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return WeeklyTaskTile(
          key: ValueKey(task.id),
          task: task,
          onToggle: () => notifier.toggleTask(task.id),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WeeklyTaskForm(date: date, task: task),
            ),
          ),
          onDelete: () => notifier.deleteTask(task.id),
        );
      },
    );
  }
}
