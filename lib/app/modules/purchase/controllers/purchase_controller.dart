import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/modules/purchase/model/PurchaseList.dart';
import 'package:sales_app/app/modules/purchase/repository/purchase_repository.dart';
import 'package:sales_app/app/modules/sales_entries/model/PartyInfo.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sales_app/app/modules/sales_entries/repository/sales_entries_repository.dart';

class PurchaseController extends GetxController {
  final PurchaseRepository purchaseRepository;

  PurchaseController({required this.purchaseRepository});
  final SalesEntriesRepository _salesEntriesRepository =
      SalesEntriesRepository();

  var purchases = <Purchaselist>[].obs;
  var isLoading = false.obs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxInt qty = 0.obs;

  final RxnString selectedParty = RxnString();
  final RxnString selectedPartyName = RxnString();
  RxList<PartyInfo> partyList = RxList();
  final partyMap = <String, String>{};
  Item? selectedPartyItem;

  RxList<Purchaselist> designList = RxList();
  final RxnString selectedDesignName = RxnString();
  Item? selectedDesignItem;
  final RxnInt designId = RxnInt();

  RxList<Purchaselist> locationList = RxList();
  final RxnString selectedLocationName = RxnString();
  Item? selectedLocationItem;
  final RxnInt locationId = RxnInt();
  final TextEditingController qtyController = TextEditingController();

  @override
  void onInit() {
    fetchPurchases();
    super.onInit();
    loadData();
    selectedDate.value = selectedDate.value ?? DateTime.now();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      await fetchParties();
      await fetchStocks();
      await fetchLocation();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStocks() async {
    try {
      final designResponse = await purchaseRepository.fetchDesigns();
      if (designResponse.isEmpty) {
        print("WARNING: Design list is empty!");
      } else {
        print("INFO: Design list fetched successfully.");
      }

      // Update designlist with fetched data and sort
      designList.value = designResponse;
      designList.sort((a, b) => (a.designNo ?? '').compareTo(b.designNo ?? ''));
    } catch (e) {
      print('Error in PurchaseController while fetching stocks: $e');
    }
  }

  Future<void> fetchLocation() async {
    try {
      final response = await purchaseRepository.fetchLocation();

      if (response.isEmpty) {
        print("WARNING: Location list is empty!");
      } else {
        print("INFO: Location list fetched successfully.");
      }

      locationList.value = response;
      locationList.sort(
        (a, b) => (a.locationName ?? '').compareTo(b.locationName ?? ''),
      );
    } catch (e) {
      print('Error in PurchaseController while fetching locations: $e');
    }
  }

  Future<void> fetchParties() async {
    try {
      final partyResponse = await _salesEntriesRepository.fetchParties();

      // Update partyList with fetched data and sort
      partyList.value = partyResponse;
      partyList.sort((a, b) => a.partyName.compareTo(b.partyName));
    } catch (e) {
      print('Error in PurchaseController while fetching parties: $e');
    }
  }

  Future<void> fetchPurchases() async {
    try {
      isLoading(true);
      var result = await purchaseRepository.getAllPurchases();
      purchases.assignAll(result);
    } finally {
      isLoading(false);
    }
  }

  Future<void> addPurchaseWithFunction() async {
    try {
      isLoading(true);

      // Enhanced validation
      if (selectedParty.value == null) {
        throw Exception('Please select a party');
      }
      if (designId.value == null || designId.value == 0) {
        throw Exception('Please select a valid design');
      }
      if (locationId.value == null || locationId.value == 0) {
        throw Exception('Please select a valid location');
      }
      if (qty.value <= 0) {
        throw Exception('Quantity must be greater than 0');
      }

      final response = await Supabase.instance.client.rpc(
        'purchase_entry_and_update',
        params: {
          '_date': DateFormat('yyyy-MM-dd').format(selectedDate.value),
          '_party_id': int.parse(selectedParty.value!),
          '_design_id': designId.value,
          '_quantity': qty.value,
          '_location_id': locationId.value,
        },
      );

      await fetchPurchases();
      clearForm();
      Get.snackbar(
        'Success',
        'Purchase entry saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      final errorMessage =
          e is PostgrestException ? e.details ?? e.message : e.toString();
      Get.snackbar(
        'Error',
        'Failed to add purchase: $errorMessage',
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  void clearForm() {
    // Clear values
    selectedParty.value = null;
    selectedPartyName.value = null;
    selectedDesignName.value = null;
    selectedLocationName.value = null;
    designId.value = null;
    locationId.value = null;
    qty.value = 0;
    qtyController.text = '';
    selectedDate.value = DateTime.now();

    // Clear selected items
    selectedPartyItem = null;
    selectedDesignItem = null;
    selectedLocationItem = null;

    // Reset form if needed
    _formKey.currentState?.reset();
    fetchStocks(); // Refresh design list
    fetchLocation();
  }

  @override
  void onClose() {
    qtyController.dispose();
    super.onClose();
  }
}
