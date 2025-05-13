import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class ReminderModel {
  final int id;
  final String title;
  final DateTime dueDate;
  final String status; // 'pending' or 'complete'
  final TimeOfDay? customTime; // optional time

  ReminderModel({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    this.customTime,
  });
}

class NotificationScheduler {
  static const _defaultHours = [11, 16]; // 11 AM and 4 PM

  static Future<void> scheduleNotifications(List<ReminderModel> reminders) async {
    final existing = await AwesomeNotifications().listScheduledNotifications();
    final timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

    for (final reminder in reminders) {
      if (reminder.status != 'pending') continue;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(reminder.dueDate.year, reminder.dueDate.month, reminder.dueDate.day);
      final baseDate = due.isBefore(today) ? today : due;

      if (reminder.customTime != null) {
        // Custom time: Schedule only once
        final custom = reminder.customTime!;
        final scheduleTime = DateTime(baseDate.year, baseDate.month, baseDate.day, custom.hour, custom.minute);

        if (scheduleTime.isBefore(now)) continue;

        final id = reminder.id;
        final alreadyScheduled = existing.any((n) => n.content?.id == id);
        if (alreadyScheduled) continue;

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: 'Reminder: ${reminder.title}',
            body: 'This item is still pending!',
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar(
            year: scheduleTime.year,
            month: scheduleTime.month,
            day: scheduleTime.day,
            hour: scheduleTime.hour,
            minute: scheduleTime.minute,
            second: 0,
            timeZone: timeZone,
            repeats: false,
            preciseAlarm: true,
          ),
        );
      } else {
        // Default times: 11 AM and 4 PM
        for (final hour in _defaultHours) {
          final scheduleTime = DateTime(baseDate.year, baseDate.month, baseDate.day, hour);

          if (scheduleTime.isBefore(now)) continue;

          final id = hour == 11 ? reminder.id : reminder.id + 100000;
          final alreadyScheduled = existing.any((n) => n.content?.id == id);
          if (alreadyScheduled) continue;

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: id,
              channelKey: 'basic_channel',
              title: 'Reminder: ${reminder.title}',
              body: 'This item is still pending!',
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar(
              year: scheduleTime.year,
              month: scheduleTime.month,
              day: scheduleTime.day,
              hour: scheduleTime.hour,
              minute: 0,
              second: 0,
              timeZone: timeZone,
              repeats: due.isBefore(today), // Only repeat if overdue
              preciseAlarm: true,
            ),
          );
        }
      }
    }
  }


  static Future<void> cancelReminder(int id) async {
    await AwesomeNotifications().cancel(id); // Morning
    await AwesomeNotifications().cancel(id + 100000); // Evening
  }
}
