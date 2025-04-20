import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/core/utils/notification_manager.dart';

class PayReminderController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var reminders = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;


  @override
  void onInit() {
    super.onInit();
    fetchReminders();
  }

  void fetchReminders() async {
    try {
      isLoading.value = true;
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final sevenDaysBefore = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 7)));

      final response = await supabase
          .from('pay_reminder')
          .select('*, parties(partyname)')
          .gte('reminder_date', sevenDaysBefore)
          .order('reminder_date', ascending: true);

      reminders.value = response;

      for (var reminder in response) {
        final reminderDate = DateTime.parse(reminder['reminder_date']);
        if (reminderDate.isAfter(now)) {
          await NotificationManager.scheduleReminderNotification(
            reminder['id'],
            "Payment Reminder",
            "Reminder for ${reminder['parties']['partyname']}",
            reminderDate,
          );
        }
      }
    } catch (e) {
      print("Error fetching reminders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await supabase.from('pay_reminder').delete().match({'id': id});
      fetchReminders();
    } catch (e) {
      print("Error deleting reminder: $e");
    }
  }

  Future<void> updateReminder(int id, String status) async {
    try {
      await supabase.from('pay_reminder').update({'status': status}).eq('id', id);
      fetchReminders();
    } catch (e) {
      print("Error updating status: $e");
    }
  }
}
