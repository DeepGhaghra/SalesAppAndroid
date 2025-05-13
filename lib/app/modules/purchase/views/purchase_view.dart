import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/modules/purchase/controllers/purchase_controller.dart';
import '../controllers/purchase_controller.dart';

class PurchaseViewScreen extends GetView<PurchaseController> {
  const PurchaseViewScreen({super.key});

  void _showAddpurchaseSheet(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(title: Text('Stock View')),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Design Number',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed:
                      () => controller.fetchStock(
                        controller.searchController.text,
                      ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Obx(
              () =>
                  controller.isLoading.value
                      ? CircularProgressIndicator()
                      : Expanded(
                        child: ListView.builder(
                          itemCount: controller.stockData.length,
                          itemBuilder: (context, index) {
                            final stock = controller.stockData[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  stock['design_id']['design_no'] ??
                                      'No Design',
                                ),
                                subtitle: Text(
                                  'Location: ${stock['location_id']['name']}\nQuantity: ${stock['quantity']}',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddpurchaseSheet(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
