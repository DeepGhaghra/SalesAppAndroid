import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/data/service/supabase_service.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockTransferController extends GetxController {
  final isLoading = false.obs;

  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  final RxList<DesignModel> designList = <DesignModel>[].obs;
  final RxList<LocationModel> allLocations = <LocationModel>[].obs;
  final RxList<LocationModel> availableFromLocations = <LocationModel>[].obs;
  final RxMap<int, int> designLocationQuantities = <int, int>{}.obs;

  final Rxn<DesignModel> selectedDesign = Rxn<DesignModel>();
  final Rxn<LocationModel> selectedFromLocation = Rxn<LocationModel>();
  final Rxn<LocationModel> selectedToLocation = Rxn<LocationModel>();
  final quantityController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchDesignsWithStock(), fetchAllLocations()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllLocations() async {
    try {
      final data = await _supabaseService.fetchAll('locations');
      allLocations.value = data.map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      SnackbarUtil.showError("Failed to load locations: $e");
    }
  }

  Future<void> fetchDesignsWithStock() async {
    try {
      final response = await supabase
          .from('stock')
          .select('''
            design_id, 
            products_design!inner(id, design_no),
            quantity
          ''')
          .gt('quantity', 0);
      // Create map to keep unique designs by design_id
      final Map<int, Map<String, dynamic>> uniqueDesigns = {};

      for (final row in response) {
        final id = row['design_id'] as int;

        // Only add if design_id not already in map
        if (!uniqueDesigns.containsKey(id)) {
          uniqueDesigns[id] = row;
        }
      }
      designList.value =
          uniqueDesigns.values
              .map(
                (e) => DesignModel.fromJson({
                  'id': e['products_design']['id'],
                  'design_no': e['products_design']['design_no'],
                }),
              )
              .toList();
    } catch (e) {
      SnackbarUtil.showError("Failed to load designs: $e");
    }
  }

  Future<void> fetchAvailableFromLocations(int designId) async {
    try {
      final response = await supabase
          .from('stock')
          .select('''
            location_id, 
            locations!inner(id, name),
            quantity,design_id
          ''')
          .eq('design_id', designId)
          .gt('quantity', 0);

      // Clear previous data
      availableFromLocations.clear();
      designLocationQuantities.clear();

      availableFromLocations.value =
          response
              .where((item) => item['design_id'] == designId)
              .map(
                (e) => LocationModel.fromJson({
                  'id': e['locations']['id'],
                  'name': e['locations']['name'],
                }),
              )
              .toList();

      // Store quantities for display
      for (var item in response) {
        designLocationQuantities[item['location_id']] = item['quantity'];
      }
    } catch (e) {
      SnackbarUtil.showError("Failed to load available locations: $e");
    }
  }

  Future<void> transferStock() async {
    if (selectedFromLocation.value!.id == selectedToLocation.value!.id) {
      SnackbarUtil.showError(
        "Invalid Transfer, From and To locations cannot be the same.",
      );

      return;
    }
    if (selectedDesign.value == null ||
        selectedFromLocation.value == null ||
        selectedToLocation.value == null ||
        quantityController.text.isEmpty ||
        int.tryParse(quantityController.text) == null ||
        int.parse(quantityController.text) <= 0) {
      SnackbarUtil.showError("Please fill all fields");
      return;
    }
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final designId = selectedDesign.value!.id;
    final fromLocationId = selectedFromLocation.value!.id;
    final toLocationId = selectedToLocation.value!.id;
    // Check available quantity
    final availableQty = designLocationQuantities[fromLocationId] ?? 0;
    if (quantity > availableQty) {
      SnackbarUtil.showError(
        "Insufficient Stock,Available quantity: $availableQty",
      );
      return;
    }
    isLoading.value = true;

    try {
      // Insert into stock_transfers table
      await supabase.rpc(
        'transfer_stock_func',
        params: {
          'p_design_id': designId,
          'p_from_location_id': fromLocationId,
          'p_to_location_id': toLocationId,
          'p_quantity': quantity,
        },
      );
      SnackbarUtil.showSuccess("Stock transferred successfully!");

      await loadData();

      resetUI();
    } catch (e) {
      SnackbarUtil.showError("Failed to transfer stock: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onDesignChanged(DesignModel? design) async {
    selectedDesign.value = design;
    selectedFromLocation.value = null;
    availableFromLocations.value = [];
    selectedToLocation.value = null;
    availableFromLocations.clear();
    designLocationQuantities.clear();
    quantityController.clear();
    if (design != null) {
      isLoading.value = true;
      fetchAvailableFromLocations(design.id);
      isLoading.value = false;
    }
  }

  void resetUI() {
    selectedDesign.value = null;
    selectedFromLocation.value = null;
    selectedToLocation.value = null;
    quantityController.clear();

    availableFromLocations.clear();
    designLocationQuantities.clear();

    update();
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
}
