import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  Widget _buildPartySearchField() {
    return Obx(() {
      return Column(
        children: [
          TextField(
            controller: controller.partyController,
            focusNode: controller.partyFocusNode,
            decoration: const InputDecoration(
              labelText: "Search by Party Name to edit product prices",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onTap: () {
              if (!controller.isUserTyping.value) {
                controller.partySuggestions.clear();
              }
            },
            onChanged: controller.fetchPartySuggestions,
          ),
          if (controller.partySuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: controller.partySuggestions.map((party) {
                  return ListTile(
                    title: Text(party),
                    onTap: () {
                      controller.partyController.text = party;
                      controller.partySuggestions.clear();
                      controller.isUserTyping.value = false;
                      controller.partyFocusNode.unfocus();
                      controller.fetchPartyPrices(party);
                    },
                  );
                }).toList(),
              ),
            ),
        ],
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
            _buildPartySearchField(),
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
