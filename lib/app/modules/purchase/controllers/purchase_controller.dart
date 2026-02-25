import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/modules/purchase/model/PurchaseList.dart';
import 'package:sales_app/app/modules/purchase/repository/purchase_repository.dart';
import 'package:sales_app/app/modules/sales_entries/model/PartyInfo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sales_app/app/modules/sales_entries/repository/sales_entries_repository.dart';

class PurchaseController extends GetxController {
  final PurchaseRepository purchaseRepository;

  PurchaseController({required this.purchaseRepository});
  final SalesEntriesRepository _salesEntriesRepository =
      SalesEntriesRepository();

  var purchases = <Purchaselist>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

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
  RxList<BulkPurchaseItem> bulkPurchaseItems = RxList<BulkPurchaseItem>();
  RxList<Purchaselist> recentPurchases = RxList<Purchaselist>();

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
      addNewRow();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStocks() async {
    try {
      final designResponse = await purchaseRepository.fetchDesigns();

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

  void addNewRow() {
    bulkPurchaseItems.add(BulkPurchaseItem());
  }

  void removeRow(int index) {
    if (bulkPurchaseItems.length > 1) {
      bulkPurchaseItems.removeAt(index);
    } else {
      SnackbarUtil.showError('At least one row is required');
    }
  }

  Future<void> fetchPurchases() async {
    try {
      isLoading(true);
      var result = await purchaseRepository.getAllPurchases();
      recentPurchases.assignAll(result);
    } finally {
      isLoading(false);
    }
  }

  Future<void> saveBulkPurchase() async {
    try {
      isLoading(true);

      // Enhanced validation
      if (selectedParty.value == null) {
        throw Exception('Please select a party');
      } // Validate all rows
      for (var item in bulkPurchaseItems) {
        if (item.designId == null || item.designId == 0) {
          throw Exception('Please select a design in all rows');
        }
        if (item.locationId == null || item.locationId == 0) {
          throw Exception('Please select a location in all rows');
        }
        if (item.quantity == null || item.quantity! <= 0) {
          throw Exception('Quantity must be greater than 0 in all rows');
        }
      }
      // Prepare batch data
      final batchData =
          bulkPurchaseItems.map((item) {
            return {
              'date': DateFormat('yyyy-MM-dd').format(selectedDate.value),
              'party_id': int.parse(selectedParty.value!),
              'design_id': item.designId,
              'location_id': item.locationId,
              'quantity': item.quantity,
            };
          }).toList();

      // Call Supabase function for each item (or implement a bulk RPC if available)
      for (var item in batchData) {
        await Supabase.instance.client.rpc(
          'purchase_entry_and_update',
          params: {
            '_date': item['date'],
            '_party_id': item['party_id'],
            '_design_id': item['design_id'],
            '_quantity': item['quantity'],
            '_location_id': item['location_id'],
          },
        );
      }

      await fetchPurchases();

      clearForm();
      SnackbarUtil.showSuccess('Purchase entry saved successfully');
    } catch (e) {
      final errorMessage =
          e is PostgrestException ? e.details ?? e.message : e.toString();
      SnackbarUtil.showError('Failed to add purchase: $errorMessage');
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
    bulkPurchaseItems.clear();
    // Reset form if needed
    _formKey.currentState?.reset();
    fetchStocks(); // Refresh design list
    fetchLocation();
    addNewRow();
  }

  @override
  void onClose() {
    qtyController.dispose();
    super.onClose();
  }
}

class BulkPurchaseItem {
  int? designId;
  String? designName;
  int? locationId;
  String? locationName;
  int? quantity;
  TextEditingController quantityController = TextEditingController();

  BulkPurchaseItem({
    this.designId,
    this.designName,
    this.locationId,
    this.locationName,
    this.quantity,
  });
}
