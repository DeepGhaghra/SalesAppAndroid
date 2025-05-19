import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/common/base_screen.dart';
import 'package:sales_app/app/modules/stock_view/views/stocktransfer_view.dart';
import 'package:sales_app/app/routes/app_pages.dart';
import 'package:universal_html/js.dart';
import '../controllers/stock_controller.dart';

class StockViewScreen extends GetView<StockController> {
  const StockViewScreen({super.key});

  void _showAddStockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Stock",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: controller.productController,
                decoration: InputDecoration(labelText: "Design Number"),
              ),
              TextField(
                controller: controller.quantityController,
                decoration: InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: controller.locationController,
                decoration: InputDecoration(labelText: "Location"),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.addStock(context),
                child: Text("Add Stock"),
              ),
            ],
          ),
        );
      },
    );
  }

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
                          labelText: 'Search Design Number',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed:
                                () => controller.fetchStock(
                                  controller.searchController.text.trim(),
                                ),
                          ),
                        ),
                        onSubmitted:
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
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2, // 50%
                                          child: Text(
                                            stock['design_id']['design_no'] ??
                                                'No Design',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
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
              onPressed: () => _showAddStockSheet(context),
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
}
