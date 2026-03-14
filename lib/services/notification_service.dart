import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings: initSettings);
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _notifications.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Expense Reminder',
      channelDescription: 'Reminds you to log your daily expenses',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: 0,
      title: '💰 Daily Expense Reminder',
      body: 'Don\'t forget to log your expenses today!',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await _notifications.cancelAll();
  }

  Future<void> testNotification() async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 10),
    );
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Expense Reminder',
      channelDescription: 'Test notification',
      importance: Importance.max,
      priority: Priority.max,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.zonedSchedule(
      id: 99,
      title: '🔔 Test Notification',
      body: 'Notifications are working! ✅',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showBudgetAlert(double spent, double budget) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alert',
      'Budget Alert',
      channelDescription: 'Alerts when budget is exceeded',
      importance: Importance.max,
      priority: Priority.max,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id: 1,
      title: '⚠️ Budget Alert',
      body:
          'You spent ₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)} budget!',
      notificationDetails: details,
    );
  }

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dailyReminder') ?? false;
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyReminder', value);
  }

  Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reminderHour') ?? 20;
  }

  Future<int> getReminderMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reminderMinute') ?? 0;
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderHour', hour);
    await prefs.setInt('reminderMinute', minute);
  }
}
