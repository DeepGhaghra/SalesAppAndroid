import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/pay_reminder_controller.dart';

class PayReminderView extends GetView<PayReminderController> {
  const PayReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Reminders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search Party",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => controller.searchQuery.value = value,
            ),
          ),
          Expanded(
            child: Obx(() {
              final filteredReminders = controller.reminders.where((reminder) {
                final party = reminder['parties']['partyname'] ?? '';
                return party.toLowerCase().contains(controller.searchQuery.value.toLowerCase());
              }).toList();

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: filteredReminders.length,
                itemBuilder: (context, index) {
                  final reminder = filteredReminders[index];
                  final bgColor = reminder['status'] == 'Pending'
                      ? Colors.grey.shade100
                      : Colors.green.shade100;

                  return Card(
                    color: bgColor,
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text(
                        reminder['parties']['partyname'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Reminder: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(reminder['reminder_date']))}"),
                          if (reminder['description'] != null)
                            Text("Note: ${reminder['description']}", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<String>(
                            value: reminder['status'],
                            items: ['Pending', 'Completed'].map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.updateReminder(reminder['id'], value);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => controller.deleteReminder(reminder['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
