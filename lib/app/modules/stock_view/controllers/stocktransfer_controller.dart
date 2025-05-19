import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockTransferController extends GetxController {
  final designNumber = ''.obs;
  final fromLocation = ''.obs;
  final toLocation = ''.obs;
  final quantity = ''.obs;

  final quantityController = TextEditingController();

  final isLoading = false.obs;

  final SupabaseClient supabase = Supabase.instance.client;

  List<String> locations = [];

  @override
  void onInit() {
    fetchLocations();
    super.onInit();
  }

  Future<void> fetchLocations() async {
    final response = await supabase.from('locations').select();
    locations = List<String>.from(response.map((e) => e['name']));
    update();
  }

  Future<void> transferStock() async {
    if (fromLocation.value == toLocation.value) {
      Get.snackbar(
        "Invalid Transfer",
        "From and To locations cannot be the same.",
      );
      return;
    }

    isLoading.value = true;

    try {
      // Get design ID
      final designResponse =
          await supabase
              .from('products_design')
              .select('id')
              .eq('design_no', designNumber.value)
              .maybeSingle();

      if (designResponse == null) {
        Get.snackbar("Error", "Design not found");
        return;
      }

      final designId = designResponse['id'];

      // Find or create stock entries and update accordingly
      await supabase.rpc(
        'transfer_stock',
        params: {
          'design_id': designId,
          'from_location': fromLocation.value,
          'to_location': toLocation.value,
          'qty': int.parse(quantity.value),
        },
      );

      Get.back();
      Get.snackbar("Success", "Stock transferred successfully!");
    } catch (e) {
      Get.snackbar("Error", "Failed to transfer stock: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
