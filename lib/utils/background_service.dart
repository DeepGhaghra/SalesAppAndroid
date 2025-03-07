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
void onStart(ServiceInstance service) {
  print("🔄 Background service started");

  // ✅ Listen for stop requests
  service.on("stopService").listen((event) {
    print("⏹ Stopping background service...");
    timer?.cancel(); 
    service.stopSelf();
  });

  checkAndScheduleReminders(service);

  timer = Timer(Duration(hours: 1), () {
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

  final reminders = await Supabase.instance.client
      .from('pay_reminder')
      .select('id, reminder_date, status, description, parties(partyname)')
      .eq('reminder_date', today);

  for (var reminder in reminders) {
    final reminderDate = DateTime.parse(reminder['reminder_date']);
    final scheduledTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      17,
      30,
      0,
    );
    await NotificationService.scheduleReminderNotification(
      reminder['id'],
      "Payment Reminder",
      "Reminder for ${reminder['parties']['partyname']}",
      scheduledTime,
    );
  }
}
