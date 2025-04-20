import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartyController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  RxList<Map<String, dynamic>> parties = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> folders = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredParties = <Map<String, dynamic>>[].obs;
  RxMap<int, List<int>> partyFolderMapping = <int, List<int>>{}.obs;

  RxString searchQuery = ''.obs;
  RxnInt selectedFolderId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    final partyResponse = await supabase.from('parties').select();
    final folderResponse = await supabase.from('folders').select();
    final mappingResponse = await supabase.from('party_folders').select();

    parties.value = List<Map<String, dynamic>>.from(partyResponse).map((party) {
      return {
        'id': party['id'],
        'name': party['partyname'] ?? 'Unknown Party',
      };
    }).toList();

    folders.value = List<Map<String, dynamic>>.from(folderResponse).map((folder) {
      return {
        'id': folder['id'],
        'folder_name': folder['folder_name'] ?? 'Unknown Folder',
      };
    }).toList();

    partyFolderMapping.clear();

    for (var map in mappingResponse) {
      int partyId = map['party_id'];
      int folderId = map['folder_id'];
      partyFolderMapping.update(
        partyId,
            (value) => [...value, folderId],
        ifAbsent: () => [folderId],
      );
    }

    applyFilters();
  }

  void applyFilters() {
    filteredParties.value = parties.where((party) {
      final name = party['name']?.toLowerCase() ?? '';
      final matchesSearch = name.contains(searchQuery.value.toLowerCase());
      final matchesFolder = selectedFolderId.value == null ||
          (partyFolderMapping[party['id']]?.contains(selectedFolderId.value) ?? false);
      return matchesSearch && matchesFolder;
    }).toList();
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
    applyFilters();
  }

  void updateSelectedFolder(int? value) {
    selectedFolderId.value = value;
    applyFilters();
  }

  Future<void> toggleFolder(int partyId, int folderId, bool isSelected) async {
    String partyName = parties.firstWhere((party) => party['id'] == partyId, orElse: () => {'name': 'Unknown Party'})['name'];
    String folderName = folders.firstWhere((folder) => folder['id'] == folderId, orElse: () => {'folder_name': 'Unknown Folder'})['folder_name'];

    if (isSelected) {
      await supabase.from('party_folders').insert({'party_id': partyId, 'folder_id': folderId});
      Fluttertoast.showToast(msg: "$folderName assigned successfully! to $partyName");
      partyFolderMapping.update(partyId, (list) => [...list, folderId], ifAbsent: () => [folderId]);
    } else {
      final response = await supabase
          .from('party_folders')
          .select('id')
          .eq('party_id', partyId)
          .eq('folder_id', folderId)
          .maybeSingle();

      if (response != null) {
        await supabase.from('party_folders').delete().eq('id', response['id']);
        Fluttertoast.showToast(msg: "$folderName unassigned successfully! for $partyName");
        partyFolderMapping[partyId]?.remove(folderId);
      } else {
        Fluttertoast.showToast(msg: "$folderName mapping not found!");
      }
    }

    applyFilters();
  }
}
