import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import '../controllers/price_list_controller.dart';


class PriceListView extends GetView<PriceListController> {
  const PriceListView({super.key});

  void _showEditPriceDialog(int productId, String productName) {
    final priceController = TextEditingController(
      text: controller.partyPrices[productId]?.toString() ?? "",
    );

    Get.dialog(
      AlertDialog(
        title: Text("Edit Price for $productName"),
        content: TextField(
          controller: priceController,
          decoration: const InputDecoration(labelText: "Enter New Price"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updatePrice(
                productId,
                priceController.text.trim(),
                Get.context!,
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
Widget _buildPartyDropdown() {
  return Obx(() {
    return SearchableDropdown(
      items: controller.partyDropdownItems,
      selectedItem: controller.selectedParty.value,
      labelText: "Search by Party Name to edit product prices",
      onItemSelected: controller.onPartySelected,
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Price List")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildPartyDropdown(),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (controller.fullProductList.isEmpty) {
                  return const Center(child: Text("No products found in database."));
                }

                return ListView.builder(
                  itemCount: controller.fullProductList.length,
                  itemBuilder: (context, index) {
                    final product = controller.fullProductList[index];
                    final int productId = product['id'];
                    final String productName = product['product_name'] ?? 'Unknown Product';
                    final int basePrice = int.tryParse(product['product_rate']?.toString() ?? '0') ?? 0;
                    final bool hasCustomPrice = controller.partyPrices.containsKey(productId);
                    final int? customPrice = hasCustomPrice ? controller.partyPrices[productId] : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _showEditPriceDialog(productId, productName),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.currency_rupee_sharp, color: Colors.green),
                                    const SizedBox(width: 5),
                                    Text(
                                      hasCustomPrice ? "₹${customPrice!.toStringAsFixed(2)}" : "Not Set",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: hasCustomPrice ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.local_offer, color: Colors.blue),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Base: ₹${basePrice.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
