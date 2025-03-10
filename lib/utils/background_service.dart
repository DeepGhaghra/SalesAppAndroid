import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'notify_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onBackground: onIosBackground,
      onForeground: onStart,
    ),
  );

  service.startService();
}

bool onIosBackground(ServiceInstance service) {
  return true;
}

Timer? timer;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("🔄 Background service started");
 await Supabase.initialize(
    url: 'https://bnvwbcndpfndzgcrsicc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJudndiY25kcGZuZHpnY3JzaWNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0Nzg4NzIsImV4cCI6MjA1NjA1NDg3Mn0.YDEmWHZnsVrgPbf71ytIVm4IrOf9xTqzthlhluW_OLI',
  );
  // ✅ Listen for stop requests
  service.on("stopService").listen((event) {
    print("⏹ Stopping background service...");
    timer?.cancel();
    service.stopSelf();
  });

  checkAndScheduleReminders(service);

  timer = Timer(Duration(hours: 1), () {
    print("🔄 Restarting background service...");

    onStart(service); // ✅ Restart every hour
  });
}

void stopService() {
  print("Stopping background service...");
  FlutterBackgroundService().invoke("stopService");
}

Future<void> checkAndScheduleReminders(ServiceInstance service) async {
  final now = DateTime.now();
  final today =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  print("Fetching reminders for today: $today");

  final reminders = await Supabase.instance.client
      .from('pay_reminder')
      .select('id, reminder_date, status, description, parties(partyname)')
      .eq('reminder_date', today);
  print("Reminders fetched: ${reminders.length}");

  for (var reminder in reminders) {
    final reminderDate = DateTime.parse(reminder['reminder_date']);
    final scheduledTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      19,
      15,
      0,
    );
    // Check if the reminder time is in the future
    if (scheduledTime.isAfter(now)) {
      print("Scheduling reminder ID ${reminder['id']} for $scheduledTime");
      await NotificationService.scheduleReminderNotification(
        reminder['id'],
        "Payment Reminder",
        "Reminder for ${reminder['parties']['partyname']}",
        scheduledTime,
      );
    } else {
      print(
        "Reminder ID ${reminder['id']} is in the past and will not be scheduled",
      );
    }
  }
}
