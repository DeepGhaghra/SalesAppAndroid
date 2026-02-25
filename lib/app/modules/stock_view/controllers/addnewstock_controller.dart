import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/data/service/supabase_service.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStockController extends GetxController {
  final isLoading = false.obs;

  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController searchController = TextEditingController();

  final TextEditingController designController = TextEditingController();
  final TextEditingController productHeadController = TextEditingController();

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final RxList<Map<String, dynamic>> stockData = <Map<String, dynamic>>[].obs;
  RxList<StockList> designList = RxList();
  RxList<StockList> locationList = RxList();

  RxList<Map<String, dynamic>> locationSuggestions =
      <Map<String, dynamic>>[].obs;
  int? selectedLocationId;
  RxList<Map<String, dynamic>> productSuggestions =
      <Map<String, dynamic>>[].obs;
  int? selectedProdHeadId;
  @override
  void onInit() {
    super.onInit();
  }

  void onLocationChanged(String value) async {
    if (value.trim().isEmpty) {
      locationSuggestions.clear();
      return;
    }

    final results = await supabase
        .from('locations')
        .select('id, name')
        .ilike('name', '%$value%')
        .limit(4);

    locationSuggestions.assignAll(List<Map<String, dynamic>>.from(results));
  }

  void selectLocation(Map<String, dynamic> location) {
    locationController.text = location['name'];
    selectedLocationId = location['id'];
    locationSuggestions.clear();
  }

  void onProductHeadChanged(String value) async {
    if (value.trim().isEmpty) {
      productSuggestions.clear();
      return;
    }

    final results = await supabase
        .from('product_head')
        .select('id, product_name')
        .ilike('product_name', '%$value%')
        .limit(4);

    productSuggestions.assignAll(List<Map<String, dynamic>>.from(results));
  }

  void selectProducts(Map<String, dynamic> productHead) {
    productHeadController.text = productHead['product_name'];
    selectedProdHeadId = productHead['id'];
    productSuggestions.clear();
  }

  Future<void> addStock() async {
    final designNo = designController.text.trim();
    final productHead = productHeadController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim());
    final locationId = selectedLocationId;

    if (designNo.isEmpty ||
        quantity == null ||
        locationId == null ||
        productHead.isEmpty) {
      SnackbarUtil.showError("Please fill all fields correctly.");
      return;
    }
    if (selectedLocationId == null) {
      SnackbarUtil.showError(
        "Please select a valid location from suggestions.",
      );
      return;
    }
    if (selectedProdHeadId == null) {
      SnackbarUtil.showError(
        "Please select a valid Product Head from suggestions.",
      );
      return;
    }

    isLoading.value = true;
    try {
      await supabase.rpc(
        'add_new_stock',
        params: {
          'p_design_no': designNo,
          'p_product_head_id': selectedProdHeadId!,
          'p_location_id': locationId,
          'p_quantity': quantity,
        },
      );
      SnackbarUtil.showSuccess("Stock added successfully!");

      designController.clear();
      productHeadController.clear();
      quantityController.clear();
      locationController.clear();
      selectedLocationId = null;
      selectedProdHeadId = null;
    } catch (e) {
      print('function execution add new Error: $e');
      SnackbarUtil.showError("Failed to add stock. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void resetUI() {
    quantityController.clear();

    update();
  }

  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
}
