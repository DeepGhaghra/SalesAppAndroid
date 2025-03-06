import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

class PaymentReminderScreen extends StatefulWidget {
  const PaymentReminderScreen({super.key});

  @override
  _PaymentReminderScreenState createState() => _PaymentReminderScreenState();
}

class _PaymentReminderScreenState extends State<PaymentReminderScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> reminders = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final sevenDaysBefore  = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: 7)));
    print("Fetching reminders between: $sevenDaysBefore and $today"); // Debug

      final response = await supabase
          .from('pay_reminder')
          .select('*, parties(partyname)')
          .gte('reminder_date', sevenDaysBefore) // Show reminders till 7 days after due date
        .order('reminder_date', ascending: true);
      print("Reminders fetched: ${response.length}"); // Debugging log

      if (mounted) {
        setState(() {
          reminders = response;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching reminders: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> deleteReminder(int id) async {
    final confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Confirm Delete"),
            content: Text("Are you sure you want to delete this reminder?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text("Delete", style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await supabase.from('pay_reminder').delete().match({'id': id});
        Fluttertoast.showToast(msg: "Reminder deleted successfully");

        fetchReminders();
      } catch (e) {
        print("Error deleting reminder: $e");
      }
    }
  }

  Future<void> updateReminder(int id, String status) async {
    try {
      await supabase
          .from('pay_reminder')
          .update({'status': status})
          .eq('id', id);
      Fluttertoast.showToast(msg: "Status updated to $status");
      fetchReminders();
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredReminders =
        reminders
            .where(
              (reminder) => reminder['parties']['partyname']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Payment Reminders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search Party",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: filteredReminders.length,
                      itemBuilder: (context, index) {
                        final reminder = filteredReminders[index];
                        Color bgColor =
                            reminder['status'] == 'Pending'
                                ? Colors.grey.shade100
                                : Colors.green.shade100;

                        return Card(
                          color: bgColor,
                          elevation: 4,
                          margin: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            title: Text(
                              reminder['parties']['partyname'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Reminder: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(reminder['reminder_date']))}",
                                ),
                                if (reminder['description'] != null)
                                  Text(
                                    "Note: ${reminder['description']}",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<String>(
                                  value: reminder['status'],
                                  items:
                                      ['Pending', 'Completed'].map((
                                        String status,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      updateReminder(reminder['id'], value);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed:
                                      () => deleteReminder(reminder['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AddReminderPage(onReminderAdded: fetchReminders),
              ),
            ),
      ),
    );
  }

  void showReminderDetails(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Reminder Details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Party: ${reminder['parties']['partyname']}"),
                Text(
                  "Reminder Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(reminder['reminder_date']))}",
                ),
                if (reminder['description'] != null)
                  Text("Description: ${reminder['description']}"),
                Text("Status: ${reminder['status']}"),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Close"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}

class AddReminderPage extends StatefulWidget {
  final VoidCallback onReminderAdded;
  AddReminderPage({required this.onReminderAdded});

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  DateTime? selectedDate;
  String? selectedPartyId;
  TextEditingController descriptionController = TextEditingController();
  List<Map<String, dynamic>> parties = [];
  bool isLoading = true; // Added to track loading

  @override
  void initState() {
    super.initState();
    fetchParties();
  }

  Future<void> fetchParties() async {
    try {
      final response = await supabase.from('parties').select();

      if (response != null) {
        setState(() {
          parties =
              response
                  .map((e) => {'id': e['id'], 'name': e['partyname']})
                  .toList();
          isLoading = false;
        });
        print("Parties List: $parties");
      }
    } catch (e) {
      print("Error fetching parties: $e");
    }
  }

  Future<void> addReminder() async {
    if (selectedPartyId == null || selectedDate == null) return;

    await supabase.from('pay_reminder').insert({
      'party_id': int.parse(selectedPartyId!),
      'reminder_date': selectedDate!.toIso8601String(),
      'description': descriptionController.text,
      'status': 'Pending',
    });
    Fluttertoast.showToast(msg: "Reminder saved succefully");

    widget.onReminderAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Payment Reminder')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(),
                ) // Show loading indicator
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select Party",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      isExpanded: true,
                      value: selectedPartyId, // Selected item
                      items:
                          parties.map((party) {
                            return DropdownMenuItem(
                              value: party['id'].toString(),
                              child: Text(party['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPartyId = value;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: "Description (Optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        selectedDate == null
                            ? "Select Reminder Date"
                            : DateFormat('dd-MM-yyyy').format(selectedDate!),
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: addReminder,
                      child: Text("Save Reminder"),
                    ),
                  ],
                ),
      ),
    );
  }
}
