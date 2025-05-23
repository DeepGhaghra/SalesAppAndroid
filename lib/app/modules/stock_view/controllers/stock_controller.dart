import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:sales_app/app/modules/stock_view/repository/stock_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final RxList<Map<String, dynamic>> stockData = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  RxList<StockList> designList = RxList();
  RxList<StockList> locationList = RxList();

  final StockRepository _stockRepository = StockRepository();
  final SupabaseClient supabase = Supabase.instance.client;

  RxList<Map<String, dynamic>> locationSuggestions =
      <Map<String, dynamic>>[].obs;
  int? selectedLocationId;
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      fetchStock('');
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStock(String searchTerm) async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('stock')
          .select('quantity, design_id!inner(id,design_no), location_id(name)')
          .gt('quantity', 0);
      ;

      final data = List<Map<String, dynamic>>.from(response);
      final filtered =
          data.where((item) {
            final designNo =
                (item['design_id']['design_no'] ?? '').toString().toLowerCase();
            final locationName =
                (item['location_id']['name'] ?? '').toString().toLowerCase();
            return designNo.contains(searchTerm.toLowerCase()) ||
                locationName.contains(searchTerm.toLowerCase());
          }).toList();

      filtered.sort(
        (a, b) => (a['design_id']['design_no'] as String)
            .toLowerCase()
            .compareTo((b['design_id']['design_no'] as String).toLowerCase()),
      );

      stockData.value = filtered;
    } catch (e) {
      SnackbarUtil.showError(
        'Error fetching stock data. Please try again later.',
      );
      stockData.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDesign() async {
    try {
      final designResponse = await _stockRepository.fetchDesigns();

      // Update designlist with fetched data and sort
      designList.value = designResponse;
      designList.sort((a, b) => (a.designNo ?? '').compareTo(b.designNo ?? ''));
    } catch (e) {
      SnackbarUtil.showError(
        'Error in StcokController while fetching stocks: $e',
      );
    }
  }

  Future<void> updateDesignName(int designId, String newName) async {
    if (newName.isEmpty) return;
    try {
      await _stockRepository.updateDesign(designId, newName);
      SnackbarUtil.showSuccess("Design Number Updated Successfully");
      loadData();
    } catch (e) {
      SnackbarUtil.showError("Error, Design Number not updated ");
    }
  }
}
