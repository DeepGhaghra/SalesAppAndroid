import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'utils/sync_utils.dart';
import 'db_help.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PartyListScreen extends StatefulWidget {
  final bool isOnline;

  const PartyListScreen({super.key, required this.isOnline});

  @override
  _PartyListScreenState createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<String> partyList = [];
  List<String> filteredList = [];
  TextEditingController searchController = TextEditingController();
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadParties();
    _subscribeToRealtimeUpdates(); // ✅ Listen for live updates
    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      setState(() {
        isOnline = connectivityResult != ConnectivityResult.none;
      });
      if (isOnline) _syncFromSupabase();
    });
  }

  Future<void> _loadParties() async {
    if (kIsWeb) {
      // Web: Fetch directly from Supabase (no caching)
      await _syncFromSupabase();
      return;
    }
    await _loadCachedParties(); // ✅ Ensure it runs before fetching online
    if (isOnline) {
      await _syncFromSupabase();
    } else {}
  }

  void _subscribeToRealtimeUpdates() {
    if (!isOnline) return; // ✅ Only subscribe when online

    supabase
        .channel('public:parties')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'parties',
          callback: (payload) {
            // ✅ Re-fetch parties when a change is detected
            _syncFromSupabase();
          },
        )
        .subscribe();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final response = await supabase.from('parties').select('partyname');
      List<String> cloudParties =
          response.map((row) => row['partyname'] as String).toList();
      cloudParties.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        partyList = cloudParties;
        filteredList = List.from(partyList);
      });

      if (!kIsWeb) {
        await DatabaseHelper.instance.cacheParties(partyList);
      }
    } catch (_) {}
  }

  Future<void> _loadCachedParties() async {
    if (kIsWeb) return; // Web fetches directly from Supabase

    List<String> cachedParties =
        await DatabaseHelper.instance.getCachedParties();
    cachedParties.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      partyList = cachedParties;
      filteredList = List.from(partyList);
    });
  }

  Future<void> _addParty(String newParty, BuildContext dialogContext) async {
    newParty = newParty.trim();
    if (newParty.isEmpty) return;
    // ✅ Convert all names to lowercase before checking for duplicates
    String newPartyLower = newParty.toLowerCase();
    List<String> lowerCaseParties =
        partyList.map((p) => p.toLowerCase()).toList();

    if (lowerCaseParties.contains(newPartyLower)) {
      Fluttertoast.showToast(msg: "⚠️ Party '$newParty' already exists!");
      return;
    }
    if (!widget.isOnline) {
      Fluttertoast.showToast(msg: "📶 No Internet! Cannot add party.");
      return;
    }

    try {
      await supabase.from('parties').insert({'partyname': newParty});
      setState(() {
        partyList.add(newParty);
        filteredList.add(newParty);
        partyList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });

      Fluttertoast.showToast(msg: "✅ Party '$newParty' added successfully!");
      Navigator.pop(dialogContext); // ✅ Close dialog only on successful add
      await _syncFromSupabase();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error adding party.");
    }
  }

  Future<void> _editParty(int index) async {
    if (!widget.isOnline) {
      Fluttertoast.showToast(msg: "📶 No Internet! Cannot edit party.");
      return;
    }

    String oldName = filteredList[index];
    TextEditingController partyController = TextEditingController(
      text: oldName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Party"),
          content: TextField(controller: partyController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedName = partyController.text.trim();
                if (updatedName.isEmpty || updatedName == oldName) return;
                // ✅ Case-insensitive check
                String updatedNameLower = updatedName.toLowerCase();
                List<String> lowerCaseParties =
                    partyList.map((p) => p.toLowerCase()).toList();

                if (lowerCaseParties.contains(updatedNameLower) &&
                    updatedNameLower != oldName.toLowerCase()) {
                  Fluttertoast.showToast(
                    msg: "⚠️ Party '$updatedName' already exists!",
                  );
                  return;
                }
                try {
                  await supabase
                      .from('parties')
                      .update({'partyname': updatedName})
                      .eq('partyname', oldName);

                  setState(() {
                    partyList[index] = updatedName;
                    filteredList[index] = updatedName;
                    partyList.sort(
                      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                    );
                  });

                  Fluttertoast.showToast(msg: "✅ Party updated successfully!");
                  await _syncFromSupabase();
                  Navigator.pop(context);
                } catch (e) {
                  Fluttertoast.showToast(msg: "Error updating party.");
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _filterParties(String query) {
    setState(() {
      filteredList =
          partyList
              .where(
                (party) => party.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _showAddPartyDialog() {
    TextEditingController partyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Party"),
          content: TextField(
            controller: partyController,
            decoration: InputDecoration(hintText: "Enter Party Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _addParty(partyController.text.trim(), context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Party List")),
      body: Column(
        children: [
          if (!isOnline) // 🔴 Show a message when offline
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.redAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "You are offline! Showing cached data.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search Party",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterParties,
            ),
          ),
          Expanded(
            child:
                (partyList.isEmpty && !isOnline && !kIsWeb)
                    ? Center(
                      child: Text(
                        "You are offline. No cached data available.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(filteredList[index]),
                            leading: Icon(Icons.person, color: Colors.blue),
                            trailing:
                                widget.isOnline
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _editParty(index),
                                    )
                                    : Icon(
                                      Icons.lock,
                                      color: Colors.grey,
                                    ), // 🔒 Disabled when offline
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          widget.isOnline
              ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: _showAddPartyDialog,
              )
              : null, // 🔒 Hide add button when offline
    );
  }
}
