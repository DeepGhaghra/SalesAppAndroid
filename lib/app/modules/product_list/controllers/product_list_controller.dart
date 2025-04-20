import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/utils/db_help.dart';

class ProductListController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var productList = <Map<String, dynamic>>[].obs;
  var filteredList = <Map<String, dynamic>>[].obs;
  var isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _loadProducts();
    _subscribeToRealtimeUpdates();
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) async {
      isOnline.value = result != ConnectivityResult.none;
      if (isOnline.value) await _syncFromSupabase();
    });
  }

  Future<void> _loadProducts() async {
    if (kIsWeb) {
      await _syncFromSupabase();
      return;
    }

    await _loadCachedProducts();
    if (isOnline.value) await _syncFromSupabase();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final response = await supabase
          .from('product_head')
          .select('id, product_name, product_rate');
      List<Map<String, dynamic>> cloudProducts =
      List<Map<String, dynamic>>.from(response);
      cloudProducts.sort((a, b) =>
          (a['product_name'] as String).toLowerCase().compareTo(
            (b['product_name'] as String).toLowerCase(),
          ));

      productList.assignAll(cloudProducts);
      filteredList.assignAll(cloudProducts);

      if (!kIsWeb) {
        await DatabaseHelper.instance.cacheProducts(cloudProducts);
      }
    } catch (e) {
      print("❌ Error syncing from Supabase: $e");
    }
  }

  Future<void> _loadCachedProducts() async {
    List<Map<String, dynamic>> cachedProducts =
    await DatabaseHelper.instance.getCachedProducts();
    productList.assignAll(cachedProducts);
    filteredList.assignAll(cachedProducts);
  }

  void _subscribeToRealtimeUpdates() {
    if (!isOnline.value) return;

    supabase
        .channel('public:product_head')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'product_head',
      callback: (payload) {
        print("🔄 Realtime update received: $payload");
        _syncFromSupabase();
      },
    )
        .subscribe();
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(productList);
      return;
    }
    filteredList.assignAll(productList.where((product) {
      final name = product['product_name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList());
  }

  void showAddProductDialog() {
    final nameController = TextEditingController();
    final rateController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text("Add New Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Product Name"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: rateController,
              decoration: InputDecoration(labelText: "Product Base Price"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _addProduct(
                nameController.text.trim(),
                rateController.text.trim(),
              );
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct(String name, String rate) async {
    if (name.isEmpty || rate.isEmpty) return;

    int sellRate = int.tryParse(rate) ?? 0;
    if (sellRate == 0) {
      Fluttertoast.showToast(
        msg: "⚠️ Invalid price format. Enter whole numbers only.",
      );
      return;
    }

    final nameLower = name.toLowerCase();
    final existingNames = productList
        .map((e) => (e['product_name'] as String).toLowerCase())
        .toList();

    if (existingNames.contains(nameLower)) {
      Fluttertoast.showToast(msg: "⚠️ Product '$name' already exists!");
      return;
    }

    try {
      await supabase.from('product_head').insert({
        'product_name': name,
        'product_rate': sellRate,
      });
      Fluttertoast.showToast(msg: "✅ Product '$name' added successfully!");
      Get.back();
      await _syncFromSupabase();
    } catch (e) {
      print("❌ Error adding product: $e");
      Fluttertoast.showToast(msg: "⚠️ Error adding product. Try again.");
    }
  }

  void editProduct(int index) {
    final old = filteredList[index];
    final nameController = TextEditingController(text: old['product_name']);
    final rateController =
    TextEditingController(text: old['product_rate'].toString());

    Get.dialog(
      AlertDialog(
        title: Text("Edit Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Product Name"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Product Price"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateProduct(index, nameController.text.trim(),
                  rateController.text.trim());
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProduct(
      int index, String updatedName, String updatedRate) async {
    if (updatedName.isEmpty || updatedRate.isEmpty) {
      Fluttertoast.showToast(msg: "⚠️ Fields cannot be empty!");
      return;
    }

    int rate = int.tryParse(updatedRate) ?? 0;
    if (rate == 0) {
      Fluttertoast.showToast(msg: "⚠️ Sell Rate must be a valid number!");
      return;
    }

    final old = filteredList[index];
    final oldName = old['product_name'];
    final oldRate = old['product_rate'];

    final nameLower = updatedName.toLowerCase();
    final existingNames = productList
        .map((e) => (e['product_name'] as String).toLowerCase())
        .toList();

    if (nameLower == oldName.toLowerCase() && rate == oldRate) {
      Get.back();
      Fluttertoast.showToast(msg: "⚠️ No changes made!");
      return;
    }

    if (existingNames.contains(nameLower) &&
        nameLower != oldName.toLowerCase()) {
      Fluttertoast.showToast(
          msg: "⚠️ Product '$updatedName' already exists!");
      return;
    }

    try {
      await supabase
          .from('product_head')
          .update({
        'product_name': updatedName,
        'product_rate': rate,
      })
          .eq('id', old['id']);
      Fluttertoast.showToast(msg: "✅ Product updated successfully!");
      Get.back();
      await _syncFromSupabase();
    } catch (e) {
      print("❌ Error updating product: $e");
      Fluttertoast.showToast(msg: "⚠️ Error updating product.");
    }
  }
}

