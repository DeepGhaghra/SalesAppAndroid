import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:sales_app/app/modules/Dashboard/bindings/dashboard_binding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/utils/ NotificationScheduler.dart';

import 'app/routes/app_pages.dart';

import 'package:sales_app/app/core/utils/notification_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Basic Notifications',
      channelDescription: 'Channel for scheduled reminders',
      importance: NotificationImportance.High,
      defaultColor: Colors.teal,
      ledColor: Colors.white,
    ),
  ], debug: true);

  // Request permissions (important!)
  await requestNotificationPermissions();

  await NotificationScheduler.scheduleNotifications([
    ReminderModel(
      id: 102,
      title: 'Invoice #123',
      dueDate: DateTime(2025, 4, 21),
      status: 'pending',
      customTime: TimeOfDay(
        hour: 0,
        minute: 18,
      ), // Will fire only once at 12:05 AM
    ),
    ReminderModel(
      id: 2,
      title: 'Follow up client',
      dueDate: DateTime(2025, 4, 20),
      status: 'pending',
      // No custom time = gets 11 AM and 4 PM if pending
    ),
  ]);
  tz.initializeTimeZones();
  await NotificationManager.setLocalTimeZone();
  var data = await Supabase.initialize(
    url: 'https://bnvwbcndpfndzgcrsicc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJudndiY25kcGZuZHpnY3JzaWNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0Nzg4NzIsImV4cCI6MjA1NjA1NDg3Mn0.YDEmWHZnsVrgPbf71ytIVm4IrOf9xTqzthlhluW_OLI',
  );

  await NotificationManager.init();
  await NotificationManager.requestExactAlarmPermission();
  await requestNotificationPermissions();
  checkNotificationPermission();
  runApp(
    GetMaterialApp(
      title: "Application",
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      initialBinding: DashboardBinding(),
      getPages: AppPages.routes,
    ),
  );
}

void checkNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final bool? granted =
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();

  print("Notifications enabled: $granted"); // ✅ Check log output
}

Future<void> requestNotificationPermissions() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (kIsWeb) {
    print("Running on the web, platform information is not available.");
  } else if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux) {
    print("✅ Android: No explicit permission required for notifications.");
    return; // ✅ Skip Android 12- requests
  }
  // iOS permission request
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}
