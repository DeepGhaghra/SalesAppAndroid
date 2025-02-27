import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'utils/sync_utils.dart'; // Import sync utils

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  _PartyListScreenState createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<String> partyList = [];
  List<String> filteredList = [];
  List<String> unsyncedParties = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParties();
    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult != ConnectivityResult.none) {
        print("📡 Internet restored! Retrying sync...");
        await _syncUnsyncedParties();
        await _syncFromSupabase();
        await _syncOfflineUpdates();
      }
    });
  }

  Future<void> _loadParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedParties = prefs.getStringList('party_list');
    List<String>? savedUnsyncedParties = prefs.getStringList(
      'unsynced_parties',
    );

    if (savedParties != null) {
      savedParties.sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      ); // Sort before setting state

      setState(() {
        partyList = savedParties;
        filteredList = List.from(partyList);
      });
    }

    if (savedUnsyncedParties != null) {
      setState(() {
        unsyncedParties = savedUnsyncedParties;
      });
      print("Loaded unsynced parties: $unsyncedParties");
    }

    if (await ConnectivityUtils.hasInternet()) {
      await _syncUnsyncedParties();
      await _syncFromSupabase();
      await _syncOfflineUpdates();
    }
  }

  Future<void> _saveParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('party_list', partyList);
  }

  Future<void> _saveUnsyncedParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unsynced_parties', unsyncedParties);
    print("Unsynced parties saved locally: $unsyncedParties");
  }

  Future<void> _syncOfflineUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offlineUpdates =
        prefs.getStringList('offlineUpdates') ?? [];

    if (offlineUpdates.isEmpty) return;

    final List<String> successfulUpdates = [];

    try {
      for (final update in offlineUpdates) {
        final parts = update.split('=>');
        if (parts.length != 2) continue;

        final oldName = parts[0];
        final newName = parts[1];

        try {
          // Get party ID
          final response =
              await supabase
                  .from('parties')
                  .select('id')
                  .ilike('partyname', oldName)
                  .maybeSingle();

          if (response != null) {
            await supabase
                .from('parties')
                .update({'partyname': newName})
                .eq('id', response['id']);

            successfulUpdates.add(update);
            print("✅ Updated: $oldName → $newName");
          }
        } catch (e) {
          print("🔴 Failed update $oldName → $newName: ${e.toString()}");
        }
      }

      // Remove successful updates
      offlineUpdates.removeWhere((u) => successfulUpdates.contains(u));
      await prefs.setStringList('offlineUpdates', offlineUpdates);
    } catch (e) {
      print("🛑 Critical update error: ${e.toString()}");
    }
  }

  Future<void> _syncFromSupabase() async {
    if (!await ConnectivityUtils.hasInternet()) {
      print("❌ No internet, skipping Supabase sync.");
      return;
    }
    try {
      final response = await supabase.from('parties').select('id, partyname');
      List<String> cloudParties =
          response.map((row) => row['partyname'] as String).toList();
      cloudParties.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (mounted) {
        setState(() {
          partyList = cloudParties;
          filteredList = List.from(partyList);
        });
      }
      await _saveParties();
      print("✅ Synced latest party list from Supabase");
    } catch (e) {
      print("Error syncing from Supabase: $e");
    }
  }

  Future<void> _syncUnsyncedParties() async {
    if (unsyncedParties.isEmpty) return;
    print("Sync function called...");
    final prefs = await SharedPreferences.getInstance();
    final List<String> successfullySynced = [];
    try {
      // Check if all unsynced parties exist in Supabase
      for (final party in unsyncedParties) {
        try {
          final existing =
              await supabase
                  .from('parties')
                  .select('partyname')
                  .ilike('partyname', party)
                  .maybeSingle();

          if (existing == null) {
            await supabase.from('parties').insert({'partyname': party});
            successfullySynced.add(party);
            print("✅ Synced: $party");
          } else {
            print("⚠️ Skipped existing: $party");
          }
        } catch (e) {
          print("🔴 Failed to sync $party: ${e.toString()}");
        }
      }
      print("Unsynced Parties Before Sync: $unsyncedParties");

      // Clear unsynced parties list after successful sync
      if (mounted) {
        setState(() {
          unsyncedParties.removeWhere((p) => successfullySynced.contains(p));
        });
      }
      await prefs.setStringList('unsynced_parties', unsyncedParties);

      print("Successfully synced parties to Supabase.");
      print(
        "Unsynced Parties after sync: ${prefs.getStringList('unsynced_parties')}",
      );
      await _syncFromSupabase();
    } catch (e) {
      print("Error syncing pending parties to Supabase: $e");
    }
  }

  /*void _addParties() {
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
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newParty = partyController.text.trim();
                if (newParty.isNotEmpty && !partyList.contains(newParty)) {
                  setState(() {
                    partyList.add(newParty);
                    filteredList.add(newParty);
                    _saveParties();
                  });
                  // Sync new party to Supabase
                  await supabase.from('parties').insert({'name': newParty});

                  Navigator.pop(context, true);
                } else {
                  Navigator.pop(context, false);
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }*/
  /// Save parties locally and sync to cloud
  Future<void> _addParty(String newParty) async {
    newParty = newParty.trim();
    if (newParty.isEmpty) return;

    String newPartyLower = newParty.toLowerCase();

    bool isDuplicate = partyList.any(
      (party) => party.toLowerCase().trim() == newPartyLower,
    );
    if (isDuplicate) {
      _showErrorDialog("Party '$newParty' already exists.");
      return;
    }
    await Future.delayed(
      Duration(milliseconds: 50),
    ); // ✅ Small delay to prevent frame issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        partyList.add(newParty);
        filteredList.add(newParty);
        partyList.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        ); // Sort alphabetically
        filteredList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    });

    await _saveParties();
    try {
      if (await ConnectivityUtils.hasInternet()) {
        final existingParty =
            await supabase
                .from('parties')
                .select('id')
                .ilike('partyname', newParty)
                .maybeSingle();

        if (existingParty != null) {
          _showErrorDialog("Party '$newParty' already exists online.");
          return;
        }
        await supabase.from('parties').insert({'partyname': newParty});
        showToast("✅ Party '$newParty' added successfully!");
      } else {
        setState(() {
          unsyncedParties.add(newParty);
        });
        await _saveUnsyncedParties();
        showToast("📶 No Internet! '$newParty' will sync when online.");
      }
    } catch (e) {
      _showErrorDialog("Error adding party: ${e.toString()}");
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT, // Disappears automatically
      gravity: ToastGravity.BOTTOM, // Appears at the bottom
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Error", style: TextStyle(color: Colors.red)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
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
                String newParty = partyController.text.trim();
                _addParty(newParty);
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _editParty(int index) {
    int originalIndex = partyList.indexOf(filteredList[index]);
    String oldPartyName = filteredList[index];
    TextEditingController partyController = TextEditingController(
      text: oldPartyName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Party"),
          content: TextField(
            controller: partyController,
            decoration: InputDecoration(hintText: "Enter New Party Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedParty = partyController.text.trim();
                String updatedPartyLower = updatedParty.toLowerCase();

                if (updatedParty == oldPartyName) {
                  showToast("✅ Party name is unchanged.");
                  Navigator.pop(context, false);
                  return;
                }

                bool isDuplicate = partyList.any(
                  (party) =>
                      party.toLowerCase().trim() == updatedPartyLower &&
                      party != oldPartyName,
                );
                if (isDuplicate) {
                  _showErrorDialog("Party '$updatedParty' already exists.");
                  return;
                }

                try {
                  if (await ConnectivityUtils.hasInternet()) {
                    final existingParty =
                        await supabase
                            .from('parties')
                            .select('id,partyname')
                            .ilike('partyname', updatedParty)
                            .neq('partyname', oldPartyName)
                            .maybeSingle();

                    if (existingParty != null) {
                      _showErrorDialog(
                        "Party '$updatedParty' already exists online.",
                      );
                      return;
                    }

                    final response =
                        await supabase
                            .from('parties')
                            .select('id')
                            .ilike('partyname', oldPartyName)
                            .maybeSingle();

                    if (response == null) {
                      _showErrorDialog("Error: Party not found.");
                      return;
                    }

                    int partyId = response['id'];
                    await supabase
                        .from('parties')
                        .update({'partyname': updatedParty})
                        .eq('id', partyId);
                    showToast(
                      "✅ Party name '$oldPartyName' updated to '$updatedParty' successfully!",
                    );
                  } else {
                    final prefs = await SharedPreferences.getInstance();
                    List<String> offlineUpdates =
                        prefs.getStringList('offlineUpdates') ?? [];
                    offlineUpdates.add("$oldPartyName=>$updatedParty");
                    await prefs.setStringList('offlineUpdates', offlineUpdates);
                    showToast(
                      "📶 Offline! '$updatedParty' update will sync when online.",
                    );
                  }

                  // Update UI immediately
                  if (mounted) {
                    setState(() {
                      partyList[originalIndex] = updatedParty;
                      filteredList[index] = updatedParty;
                      partyList.sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                      );
                      filteredList.sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                      );
                    });
                  }

                  await _saveParties();
                  Navigator.pop(context, true);
                } catch (e) {
                  _showErrorDialog("Error updating party: ${e.toString()}");
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
      filteredList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Party List"),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _showAddPartyDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                filteredList.isEmpty
                    ? Center(child: Text("No parties available"))
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
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: Colors.green),
                              onPressed: () => _editParty(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
