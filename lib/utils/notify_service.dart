import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sales_app/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    await _setLocalTimeZone();

    //testNotification();

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

  static Future<void> _setLocalTimeZone() async {
    try {
      // Get the device's local time zone using flutter_timezone
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      print("Device time zone: $timeZoneName");

      // Set the local time zone
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("Local time zone set to: ${tz.local}");
    } catch (e) {
      print("⚠️ Error setting local time zone: $e");
      // Fallback to UTC if the time zone cannot be set
      tz.setLocalLocation(tz.getLocation('UTC'));
      print("Fallback to UTC time zone");
    }
  }

  static Future<void> scheduleReminderNotification(
    int id,
    String title,
    String body,
    DateTime reminderDate,
  ) async {
    
    // Check for exact alarm permission (Android 12+)
    if (await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ==
        false) {
      requestExactAlarmPermission();
      return;
    }
    // Set the notification time to 9:00 AM on the reminder date
    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local, // Use the local time zone
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      19, // 6 PM
      15, // 50 minutes
      0, // 0 seconds
    );
    print("Local time zone: ${tz.local}");
    print("Scheduled time in local time zone: $scheduledTime");
    print("🔔 Scheduling notification ID $id at $scheduledTime");
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
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
      );
      print("✅ Notification scheduled successfully for ID $id");
    } catch (e) {
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
