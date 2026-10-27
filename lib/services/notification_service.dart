import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/weekly_task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'task_deadlines';
  static const _channelName = 'Aufgaben-Deadlines';
  static const _channelDesc = 'Erinnerungen für Aufgaben mit Deadlines';

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskNotifications(WeeklyTaskModel task) async {
    if (task.deadline == null || task.notifications.isEmpty) return;
    for (final timing in task.notifications) {
      await _scheduleOne(task, timing);
    }
  }

  Future<void> _scheduleOne(
      WeeklyTaskModel task, NotificationTiming timing) async {
    final deadline = task.deadline!;
    final daysOffset = switch (timing) {
      NotificationTiming.sameDay => 0,
      NotificationTiming.oneDayBefore => 1,
      NotificationTiming.twoDaysBefore => 2,
    };
    final notifyDay = deadline.subtract(Duration(days: daysOffset));
    final notifyDt = DateTime(
        notifyDay.year, notifyDay.month, notifyDay.day, 9, 0);

    if (notifyDt.isBefore(DateTime.now())) return;

    final tzDt = tz.TZDateTime.from(notifyDt, tz.local);
    final id = _notificationId(task.id, timing);
    final dateStr = DateFormat('dd.MM.yyyy').format(deadline);

    final body = switch (timing) {
      NotificationTiming.sameDay =>
        '"${task.description}" ist heute fällig ($dateStr)',
      NotificationTiming.oneDayBefore =>
        '"${task.description}" ist morgen fällig ($dateStr)',
      NotificationTiming.twoDaysBefore =>
        '"${task.description}" ist in 2 Tagen fällig ($dateStr)',
    };

    await _plugin.zonedSchedule(
      id,
      'Aufgabe fällig',
      body,
      tzDt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    for (final timing in NotificationTiming.values) {
      await _plugin.cancel(_notificationId(taskId, timing));
    }
  }

  int _notificationId(String taskId, NotificationTiming timing) =>
      (taskId.hashCode.abs() % 999990) * 10 + timing.index;
}
