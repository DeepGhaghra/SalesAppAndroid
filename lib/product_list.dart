import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<String> productList = [];
  List<String> filteredList = [];
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
    }
  }

  Future<void> _saveProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('product_list', productList);
  }

  void _addProducts() {
    TextEditingController productController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Product"),
          content: TextField(
            controller: productController,
            decoration: InputDecoration(hintText: "Enter Product Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newProduct = productController.text.trim();
                if (newProduct.isNotEmpty && !productList.contains(newProduct)) {
                  setState(() {
                    productList.add(newProduct);
                    filteredList.add(newProduct);
                    _saveProducts();
                  });
                  Navigator.pop(context, true); // Notify Sales Entry Page
                } else {
                  Navigator.pop(context, false); // No change
                }
              },
              child: Text("Add"),
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
                            leading: Icon(Icons.person, color: Colors.blue),
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
