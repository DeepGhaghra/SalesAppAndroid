import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sales_app/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    testNotification();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> scheduleReminderNotification(
    int id,
    String title,
    String body,
    DateTime reminderDate,
  ) async {
    // Set the notification time to 9:00 AM on the reminder date
    DateTime scheduledTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      17,
      30,
      0,
    );
    print("🔔 Scheduling notification ID $id at $scheduledTime");
try{
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );  print("✅ Notification scheduled successfully for ID $id");} catch (e) {
    print("⚠️ Error scheduling notification: $e");
    if (e.toString().contains("exact_alarms_not_permitted")) {
      requestExactAlarmPermission(); // ✅ Ask user to allow exact alarms
    }
  }

  }

  static Future<void> testNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      'Payment Reminder',
      'Call Him',
      notificationDetails,
    );
  }
}
