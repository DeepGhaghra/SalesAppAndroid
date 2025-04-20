import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_list_controller.dart';

class ProductListView extends GetView<ProductListController> {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search Product",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: controller.filterProducts,
            ),
          ),
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        product['product_name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "₹${product['product_rate']}",
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                      leading: Icon(Icons.shopping_cart, color: Colors.blue),
                      trailing: controller.isOnline.value
                          ? IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => controller.editProduct(index),
                      )
                          : Icon(Icons.lock, color: Colors.grey),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        return controller.isOnline.value
            ? FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: controller.showAddProductDialog,
        )
            : SizedBox.shrink();
      }),
    );
  }
}
