import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/modules/sales_entries/model/SalesEntry.dart';
import 'package:sales_app/app/modules/sales_entries/repository/sales_entries_repository.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesListController extends GetxController {
  final SalesEntriesRepository _repository = SalesEntriesRepository();

  var sales = <SalesInvoiceGroup>[].obs;
  var isLoading = false.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString dateFilter = ''.obs;
  List<String> selectedProducts = [];
  List<StockList> designList = [];
  @override
  void onInit() {
    super.onInit();
    loadEntries();
  }

  void updatePartySearch(String value) {
    searchController.text = value;
    loadEntries();
  }

  void updateDateSearch(String value) {
    dateFilter.value = value;
    loadEntries();
  }

  Future<void> loadEntries() async {
    try {
      isLoading.value = true;
      final result = await _repository.fetchGroupedSales(
        partyName: searchController.text.trim(),
        date: dateFilter.value.trim().isEmpty ? null : dateFilter.value.trim(),
      );
      sales.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getProductsForInvoice(
    String invoiceNo,
  ) async {
    // Here, you need to load/select the products associated with the invoiceNo.
    // For example, filter selectedProducts or your data source by invoiceNo.
    // For demo, using all selectedProducts as example.
    final response = await Supabase.instance.client
        .from('sales_entries')
        .select('''
        id, 
        design_id,
        product_id, 
        quantity, 
        rate, 
        amount,
        products_design!inner(
          design_no,
          product_head_id,
          product_head!inner(
            product_name,
            folder_id,
            folders!inner(folder_name)
            ))
      ''')
        .eq('invoiceno', invoiceNo);

    final result = response as List<dynamic>;
    print("result : $result");
    return result
        .map(
          (row) => {
            'design_id': row['design_id'].toString(),
            'product_id': row['product_id'].toString(),
            'quantity': row['quantity'].toString(),
            'rate': row['rate'].toString(),
            'amount': row['amount'],
            'design_no': row['products_design']['design_no'].toString(),
            'product_name':
                row['products_design']['product_head']['product_name']
                    .toString(),
            'folder_name':
                row['products_design']['product_head']['folders']['folder_name']
                    .toString(),
            'location_name': row['locations']['location_name'].toString(),
          },
        )
        .toList();
  }
}
