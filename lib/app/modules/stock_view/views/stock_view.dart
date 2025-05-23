import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/common/base_screen.dart';
import 'package:sales_app/app/routes/app_pages.dart';
import '../controllers/stock_controller.dart';

class StockViewScreen extends GetView<StockController> {
  const StockViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      globalKey: GlobalKey(),

      nameOfScreen: 'Stock View',
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Design or Location',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed:
                                () => controller.fetchStock(
                                  controller.searchController.text.trim(),
                                ),
                          ),
                        ),
                        onChanged:
                            (value) => controller.fetchStock(value.trim()),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 231, 245, 247),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          color: Color.fromARGB(255, 52, 125, 131),
                        ),
                        tooltip: "Stock Transfer",
                        onPressed: _navigateToStockTransfer,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 231, 245, 247),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.add_location,
                          color: Color.fromARGB(255, 52, 125, 131),
                        ),
                        tooltip: "Locations",
                        onPressed: _navigateToLocations,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Obx(
                    () =>
                        controller.isLoading.value
                            ? Center(
                              child: SizedBox(
                                height: 48,
                                width: 48,
                                child: RefreshProgressIndicator(),
                              ),
                            )
                            : ListView.builder(
                              itemCount: controller.stockData.length,
                              itemBuilder: (context, index) {
                                final stock = controller.stockData[index];
                                return Card(
                                  color: (Colors.grey.shade200),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8, // can change to 16 also
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2, // 50%
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  stock['design_id']['design_no'] ??
                                                      'No Design',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: const Color.fromARGB(
                                                    255,
                                                    224,
                                                    133,
                                                    67,
                                                  ),
                                                ),
                                                tooltip: "Edit Design Name",
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  _showEditDialog(
                                                    context,
                                                    stock,
                                                    stock['design_id']['design_no'],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1, // 25%
                                          child: Text(
                                            "Location: ${stock['location_id']['name']}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1, // 25%
                                          child: Text(
                                            "Qty: ${stock['quantity']}",
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _navigateToAddnewStock(),
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStockTransfer() {
    Get.toNamed(Routes.STOCKTRANSFER);
  }

  void _navigateToAddnewStock() {
    Get.toNamed(Routes.ADDNEWSTOCK);
  }

  void _navigateToLocations() {
    Get.toNamed(Routes.LOCATIONS);
  }

  void _showEditDialog(
    BuildContext context,
    dynamic stock,
    String currentName,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit Design'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Design Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.updateDesignName(
                  stock['design_id']['id'],
                  nameController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
