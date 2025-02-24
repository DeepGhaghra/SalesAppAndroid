import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<String> productList = [];
  List<String> filteredList = [];
  Map<String, int> productRates = {}; // Stores product rates
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedProducts = prefs.getStringList('product_list');

    if (savedProducts != null) {
      setState(() {
        productList = savedProducts;
        filteredList = List.from(productList);
      });
      for (String product in productList) {
        setState(() {
          productRates[product] = prefs.getInt('rate_$product') ?? 0;
        });
      }
    }
  }

  Future<void> _saveProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('product_list', productList);
    for (var entry in productRates.entries) {
      await prefs.setInt('rate_${entry.key}', entry.value);
    }
  }

  void _addProducts() {
    TextEditingController productController = TextEditingController();
    TextEditingController rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Product"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productController,
                decoration: InputDecoration(hintText: "Enter Product Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Enter Product Rate"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newProduct = productController.text.trim();
                int newRate = int.tryParse(rateController.text.trim()) ?? 0;

                if (newProduct.isNotEmpty &&
                    !productList.contains(newProduct)) {
                  setState(() {
                    productList.add(newProduct);
                    filteredList.add(newProduct);
                    productRates[newProduct] = newRate;
                    _saveProducts();
                  });
                  Navigator.pop(context, true);
                } else {
                  Navigator.pop(context, false);
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

 void _editProduct(int index) async {
  String oldProductName = filteredList[index]; 
  TextEditingController productController = TextEditingController(text: oldProductName);
  TextEditingController rateController = TextEditingController(
    text: productRates[oldProductName]?.toString() ?? '0',
  );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productController,
              decoration: InputDecoration(hintText: "Enter New Product Name"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Enter New Rate"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newProductName = productController.text.trim();
              int newRate = int.tryParse(rateController.text.trim()) ?? 0;

              if (newProductName.isNotEmpty) {
                setState(() {
                  int originalIndex = productList.indexOf(oldProductName);
                  productList[originalIndex] = newProductName;
                  filteredList[index] = newProductName;

                  // Update product rates map
                  productRates.remove(oldProductName);
                  productRates[newProductName] = newRate.toInt();
                });

                // Save updated values in SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('product_list', productList);
                await prefs.remove('rate_$oldProductName'); // Remove old key
                await prefs.setInt('rate_$newProductName', newRate); // Save as integer

                // Debug print
                print("Saved: $newProductName - Rate: $newRate");

                Navigator.pop(context, true);
              }
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
}


  void _filterProducts(String query) {
    setState(() {
      filteredList =
          productList
              .where(
                (product) =>
                    product.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product List"),
        actions: [IconButton(icon: Icon(Icons.add), onPressed: _addProducts)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search Products",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child:
                filteredList.isEmpty
                    ? Center(child: Text("No products available"))
                    : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(filteredList[index]),
                            subtitle: Text(
                              "Rate: ₹${productRates[filteredList[index]]?.toStringAsFixed(2) ?? '0'}",
                            ),
                            leading: Icon(Icons.person, color: Colors.blue),
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: Colors.green),
                              onPressed: () => _editProduct(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
