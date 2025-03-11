import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PartyFolderScreen extends StatefulWidget {
  const PartyFolderScreen({Key? key}) : super(key: key);

  @override
  _PartyFolderScreenState createState() => _PartyFolderScreenState();
}

class _PartyFolderScreenState extends State<PartyFolderScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> parties = [];
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> filteredParties = [];

  Map<int, List<int>> partyFolderMapping = {};
  String searchQuery = '';
  int? selectedFolderId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final partyResponse = await supabase.from('parties').select();
    final folderResponse = await supabase.from('folders').select();
    final mappingResponse = await supabase.from('party_folders').select();

    setState(() {
      parties =
          List<Map<String, dynamic>>.from(partyResponse).map((party) {
            return {
              'id': party['id'],
              'name': party['partyname'] ?? 'Unknown Party',
            };
          }).toList();
      folders =
          List<Map<String, dynamic>>.from(folderResponse).map((folder) {
            return {
              'id': folder['id'],
              'folder_name': folder['folder_name'] ?? 'Unknown Folder',
            };
          }).toList();
      partyFolderMapping.clear();

      for (var map in mappingResponse) {
        int partyId = map['party_id'];
        int folderId = map['folder_id'];

        if (!partyFolderMapping.containsKey(partyId)) {
          partyFolderMapping[partyId] = [];
        }
        if (!partyFolderMapping[partyId]!.contains(folderId)) {
          partyFolderMapping[partyId]!.add(folderId);
        }
      }
    });
  }

  Future<void> _toggleFolder(int partyId, int folderId, bool isSelected) async {
    String partyName =
        parties.firstWhere(
          (party) => party['id'] == partyId,
          orElse: () => {'name': 'Unknown Party'},
        )['name'];
    String folderName =
        folders.firstWhere(
          (folder) => folder['id'] == folderId,
          orElse: () => {'folder_name': 'Unknown Folder'},
        )['folder_name'];
    if (isSelected) {
      await supabase.from('party_folders').insert({
        'party_id': partyId,
        'folder_id': folderId,
      });
      Fluttertoast.showToast(
        msg: "$folderName assigned successfully! to $partyName",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      setState(() {
        partyFolderMapping.putIfAbsent(partyId, () => []).add(folderId);
        _applyFilters();
      });
    } else {
      final response =
          await supabase
              .from('party_folders')
              .select('id')
              .eq('party_id', partyId)
              .eq('folder_id', folderId)
              .maybeSingle();

      if (response != null) {
        await supabase.from('party_folders').delete().eq('id', response['id']);
        Fluttertoast.showToast(
          msg: "$folderName unassigned successfully! for $partyName",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        setState(() {
          partyFolderMapping[partyId]?.remove(folderId);
          _applyFilters();
        });
      } else {
        Fluttertoast.showToast(
          msg: "$folderName mapping not found!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
    _loadData();
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      filteredParties =
          parties.where((party) {
            bool matchesSearch = party['name'].toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            bool matchesFolder =
                selectedFolderId == null ||
                (partyFolderMapping[party['id']]?.contains(selectedFolderId) ??
                    false);
            return matchesSearch && matchesFolder;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredParties =
        parties.where((party) {
          bool matchesSearch = party['name'].toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
          bool matchesFolder =
              selectedFolderId == null ||
              (partyFolderMapping[party['id']]?.contains(selectedFolderId) ??
                  false);
          return matchesSearch && matchesFolder;
        }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Party Folders")),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredParties.length,
              itemBuilder: (context, index) {
                final party = filteredParties[index];
                return ExpansionTile(
                  title: Text(party['name'] ?? 'Unnamed Party'),
                  children:
                      folders.map((folder) {
                        bool isSelected =
                            partyFolderMapping[party['id']]?.contains(
                              folder['id'],
                            ) ??
                            false;
                        return CheckboxListTile(
                          title: Text(
                            folder['folder_name'] ?? 'Unnamed Folder',
                          ),
                          value: isSelected,
                          onChanged:
                              (value) => _toggleFolder(
                                party['id'],
                                folder['id'],
                                value ?? false,
                              ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: "Search Party",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: "Filter by Folder",
              border: OutlineInputBorder(),
            ),
            value: selectedFolderId,
            items: [
              DropdownMenuItem<int>(value: null, child: Text("All Folders")),
              ...folders.map(
                (folder) => DropdownMenuItem<int>(
                  value: folder['id'],
                  child: Text(folder['folder_name']),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedFolderId = value;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }
}
