import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final RxList<Map<String, dynamic>> stockData = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchStock(String searchTerm) async {
    isLoading.value = true;
    final response = await Supabase.instance.client
        .from('stock')
        .select('product_head(product_name), quantity, locations(name)')
        .ilike('product_head.product_name', '%$searchTerm%')
        .order('product_head.product_name');

    stockData.value = List<Map<String, dynamic>>.from(response);
    isLoading.value = false;
  }

  Future<void> addStock(BuildContext context) async {
    final product = productController.text;
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final location = locationController.text;

    if (product.isEmpty || quantity <= 0 || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid details!')),
      );
      return;
    }

    await Supabase.instance.client.from('stock').insert({
      'product_id': product,
      'quantity': quantity,
      'location_id': location,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stock added successfully!')),
    );

    productController.clear();
    quantityController.clear();
    locationController.clear();
    Get.back(); // Close the bottom sheet
    fetchStock('');
  }
}
