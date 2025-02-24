import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final List<String> productList = [
    'Product X',
    'Product Y',
    'Product Z',
  ]; // Ensure this list is not empty

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product List")),
      body:
          productList.isEmpty
              ? Center(
                child: Text("No products available"),
              ) // Fallback for empty list
              : ListView.builder(
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(productList[index]),
                      leading: Icon(Icons.shopping_cart, color: Colors.green),
                    ),
                  );
                },
              ),
    );
  }
}
