import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/utils/db_help.dart';

class PartyListController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  RxList<String> partyList = <String>[].obs;
  RxList<String> filteredList = <String>[].obs;
  RxBool isOnline = RxBool(true);

  final searchController = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadParties();
    _subscribeToRealtimeUpdates();
    Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = result != ConnectivityResult.none;
      if (isOnline.value) _syncFromSupabase();
    });
    ever(searchController, _filterParties);
  }

  Future<void> _loadParties() async {
    if (kIsWeb) {
      await _syncFromSupabase();
      return;
    }
    await _loadCachedParties();
    if (isOnline.value) {
      await _syncFromSupabase();
    }
  }

  void _subscribeToRealtimeUpdates() {
    if (!isOnline.value) return;
    supabase.channel('public:parties').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'parties',
      callback: (_) => _syncFromSupabase(),
    ).subscribe();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final response = await supabase.from('parties').select('partyname');
      final cloudParties = response.map((row) => row['partyname'] as String).toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      partyList.assignAll(cloudParties);
      filteredList.assignAll(cloudParties);
      if (!kIsWeb) {
        await DatabaseHelper.instance.cacheParties(partyList);
      }
    } catch (_) {}
  }

  Future<void> _loadCachedParties() async {
    if (kIsWeb) return;
    final cached = await DatabaseHelper.instance.getCachedParties()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    partyList.assignAll(cached);
    filteredList.assignAll(cached);
  }

  Future<void> addParty(String newParty) async {
    newParty = newParty.trim();
    if (newParty.isEmpty) return;
    String newLower = newParty.toLowerCase();
    if (partyList.map((e) => e.toLowerCase()).contains(newLower)) {
      Fluttertoast.showToast(msg: "⚠️ Party '$newParty' already exists!");
      return;
    }
    if (!isOnline.value) {
      Fluttertoast.showToast(msg: "📶 No Internet! Cannot add party.");
      return;
    }

    try {
      await supabase.from('parties').insert({'partyname': newParty});
      await _syncFromSupabase();
      Fluttertoast.showToast(msg: "✅ Party '$newParty' added successfully!");
      Get.back();
    } catch (_) {
      Fluttertoast.showToast(msg: "Error adding party.");
    }
  }

  Future<void> editParty(String oldName, String updatedName) async {
    updatedName = updatedName.trim();
    if (updatedName.isEmpty || updatedName == oldName) return;
    String updatedLower = updatedName.toLowerCase();
    if (partyList.map((e) => e.toLowerCase()).contains(updatedLower) &&
        updatedLower != oldName.toLowerCase()) {
      Fluttertoast.showToast(msg: "⚠️ Party '$updatedName' already exists!");
      return;
    }

    try {
      await supabase
          .from('parties')
          .update({'partyname': updatedName})
          .eq('partyname', oldName);
      await _syncFromSupabase();
      Fluttertoast.showToast(msg: "✅ Party updated successfully!");
      Get.back();
    } catch (_) {
      Fluttertoast.showToast(msg: "Error updating party.");
    }
  }

  void _filterParties(String query) {
    filteredList.assignAll(
      partyList.where((p) => p.toLowerCase().contains(query.toLowerCase())),
    );
  }
}
