import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:sales_app/app/routes/app_pages.dart';
import '../controllers/addnewstock_controller.dart';

class AddStockScreen extends StatelessWidget {
  final controller = Get.put(AddStockController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Stock"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.toNamed(Routes.STOCKVIEW),
        ),
      ),
      body: Obx(
        () => Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add Stock",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: controller.designController,
                  decoration: InputDecoration(labelText: "Design Number"),
                ),

                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller.productHeadController,
                        decoration: const InputDecoration(
                          labelText: "Product Head",
                          hintText: "Type to search for Product Head",
                        ),
                        onChanged: controller.onProductHeadChanged,
                      ),
                      if (controller.productSuggestions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children:
                                controller.productSuggestions.map((
                                  productHead,
                                ) {
                                  return ListTile(
                                    title: Text(productHead['product_name']),
                                    onTap:
                                        () => controller.selectProducts(
                                          productHead,
                                        ),
                                  );
                                }).toList(),
                          ),
                        ),
                    ],
                  );
                }),
                TextField(
                  controller: controller.quantityController,
                  decoration: InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number,
                ),
                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller.locationController,
                        decoration: const InputDecoration(
                          labelText: "Location Name",
                          hintText: "Type to search for locations",
                        ),
                        onChanged: controller.onLocationChanged,
                      ),
                      if (controller.locationSuggestions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children:
                                controller.locationSuggestions.map((location) {
                                  return ListTile(
                                    title: Text(location['name']),
                                    onTap:
                                        () =>
                                            controller.selectLocation(location),
                                  );
                                }).toList(),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : Column(
                      children: [
                        ElevatedButton(
                          onPressed: controller.addStock,
                          child: const Text("Add Stock"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Get.toNamed(Routes.STOCKVIEW),
                          child: const Text("Back to Stock View"),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
