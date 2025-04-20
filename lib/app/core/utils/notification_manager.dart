import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ✅ Initialize Notifications & Timezones
  static Future<void> init() async {
    tz.initializeTimeZones();
    await setLocalTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings();

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(settings);
    print("✅ Notification Manager Initialized");
  }

  // ✅ Set Local Timezone
  static Future<void> setLocalTimeZone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      print("🌍 Detected Time Zone: $timeZoneName");

      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print("✅ Time zone set to: $timeZoneName");
      } else {
        throw Exception("Time zone $timeZoneName not found in database.");
      }
    } catch (e) {
      print("⚠️ Error setting local time zone: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
      print("Fallback to UTC time zone");
    }
  }

  // ✅ Request Exact Alarm Permission (Android 12+)
  static Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;

      if (status.isGranted) {
        print("✅ Exact Alarm Permission already granted.");
        return;
      }

      print("⚠️ Asking for Exact Alarm Permission...");
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      try {
        await intent.launch();
      } catch (e) {
        print("⚠️ Error launching exact alarm settings: $e");
      }
    }
  }

  // ✅ Schedule a Notification
  static Future<void> scheduleReminderNotification(
    int id,
    String title,
    String body,
    DateTime reminderDate,
  ) async {
    print("🕒 Scheduling for: $reminderDate");

    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
      reminderDate.toLocal(),
      tz.local,
    );

    print("⏳ Scheduling notification at: $scheduledTime");

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
            playSound: true,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print(
        "✅ Notification scheduled successfully for ID $id at $scheduledTime",
      );
      await listScheduledNotifications();
    } catch (e) {
      print("⚠️ Error scheduling notification: $e");
      if (e.toString().contains("exact_alarms_not_permitted")) {
        requestExactAlarmPermission();
      }
    }
  }

  // ✅ List All Pending Notifications
  static Future<void> listScheduledNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    print("🔍 Pending Notifications: ${pendingNotifications.length}");
    for (var notification in pendingNotifications) {
      print(
        "📌 Scheduled Notification: ID=${notification.id}, Title=${notification.title}, Body=${notification.body}",
      );
    }
  }

  // ✅ Test Notification (Manually Trigger)
  static Future<void> testNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification!',
      notificationDetails,
    );
  }

  // ✅ Background Service: Fetch and Schedule Reminders
  static Future<void> checkAndScheduleReminders() async {
    print("🔄 Background service running at ${DateTime.now()}");

    // Get today's date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // ✅ Today's Date

    try {
      final List<dynamic> reminders = await Supabase.instance.client
          .from('pay_reminder')
          .select('id, reminder_date, status, parties(partyname)')
          .eq(
            'reminder_date',
            today.toString().split(" ")[0],
          );

      print("📌 Reminders fetched: ${reminders.length}");

      for (var reminder in reminders) {
        DateTime reminderDate = DateTime.parse(reminder['reminder_date']);
        // ✅ Ensure reminder is for today
      if (reminderDate.year == today.year &&
          reminderDate.month == today.month &&
          reminderDate.day == today.day) {
        reminderDate = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          18,
          35,
          0,
        );
        print("🕒 Updated Reminder Date with Time: $reminderDate");

        if (!reminderDate.isBefore(now)) {
          await NotificationManager.scheduleReminderNotification(
            reminder['id'],
            "Payment Reminder",
            "Reminder for ${reminder['parties']['partyname']}",
            reminderDate,
          );
        } else {
          print(
            "❌ Reminder ID ${reminder['id']} is in the past and will not be scheduled.",
          );
        }} else {
        print("⚠️ Skipping reminder ID ${reminder['id']} - Not for today.");
      }
      }
    } catch (e) {
      print("⚠️ Error fetching reminders from Supabase: $e");
    }
  }
}
