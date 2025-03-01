import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'db_help.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductListScreen extends StatefulWidget {
  final bool isOnline;

  const ProductListScreen({super.key, required this.isOnline});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> filteredList = [];
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _subscribeToRealtimeUpdates();

    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      setState(() {
        isOnline = connectivityResult != ConnectivityResult.none;
      });
      if (isOnline) _syncFromSupabase();
    });
  }

  Future<void> _loadProducts() async {
    if (kIsWeb) {
      await _syncFromSupabase();
      return;
    }

    await _loadCachedProducts();
    if (isOnline) {
      await _syncFromSupabase();
    }
  }

  Future<void> _syncFromSupabase() async {
    try {
      final response = await supabase
          .from('products')
          .select('id, product_name, product_rate');
      List<Map<String, dynamic>> cloudProducts =
          List<Map<String, dynamic>>.from(response);
      cloudProducts.sort(
        (a, b) => (a['product_name'] as String).toLowerCase().compareTo(
          (b['product_name'] as String).toLowerCase(),
        ),
      );

      setState(() {
        productList = cloudProducts;
        filteredList = List.from(productList);
      });

      if (!kIsWeb) {
        await DatabaseHelper.instance.cacheProducts(cloudProducts);
      }
    } catch (e) {
      print("❌ Error syncing from Supabase: $e");
    }
  }

  Future<void> _loadCachedProducts() async {
    List<Map<String, dynamic>> cachedProducts =
        await DatabaseHelper.instance.getCachedProducts();
    setState(() {
      productList = cachedProducts;
      filteredList = List.from(productList);
    });
  }

  void _subscribeToRealtimeUpdates() {
    if (!isOnline) return;

    supabase
        .channel('public:products')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            print("🔄 Realtime update received: $payload");
            _syncFromSupabase();
          },
        )
        .subscribe();
  }

  void _filterProducts(String query) {
    setState(() {
      filteredList =
          productList
              .where(
                (product) => product['product_name'].toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  void _showAddProductDialog() {
    TextEditingController nameController = TextEditingController();
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
                controller: nameController,
                decoration: InputDecoration(labelText: "Product Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: rateController,
                decoration: InputDecoration(labelText: "Product Base Price"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _addProduct(
                  nameController.text.trim(),
                  rateController.text.trim(),
                  context,
                );
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProduct(
    String name,
    String rate,
    BuildContext dialogContext,
  ) async {
    if (name.isEmpty || rate.isEmpty) return;

    try {
      int sellRate = int.tryParse(rate) ?? 0;
      if (sellRate == 0) {
        Fluttertoast.showToast(
          msg: "⚠️ Invalid price format. Enter whole numbers only.",
        );
        return;
      }
      // ✅ Convert name to lowercase for case-insensitive check
      String nameLower = name.toLowerCase();

      // ✅ Check if product already exists in local list
      List<String> lowerCaseProducts =
          productList
              .map((p) => (p['product_name'] as String).toLowerCase())
              .toList();

      if (lowerCaseProducts.contains(nameLower)) {
        Fluttertoast.showToast(msg: "⚠️ Product '$name' already exists!");
        return;
      }
      await supabase.from('products').insert({
        'product_name': name,
        'product_rate': sellRate,
      });
      Fluttertoast.showToast(msg: "✅ Product '$name' added successfully!");
      Navigator.pop(dialogContext);
      await _syncFromSupabase();
    } catch (e) {
      print("❌ Error adding product: $e");
      Fluttertoast.showToast(msg: "⚠️ Error adding product. Try again.");
    }
  }

  Future<void> _editProduct(int index) async {
    if (!isOnline) {
      Fluttertoast.showToast(msg: "📶 No Internet! Cannot edit product.");
      return;
    }

    String oldName = filteredList[index]['product_name'];
    int oldRate = filteredList[index]['product_rate'];

    TextEditingController nameController = TextEditingController(text: oldName);
    TextEditingController rateController = TextEditingController(
      text: oldRate.toString(),
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
                controller: nameController,
                decoration: InputDecoration(labelText: "Product Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Product Price"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedName = nameController.text.trim();
                String updatedRate = rateController.text.trim();
                if (updatedName.isEmpty || updatedRate.isEmpty) {
                  Fluttertoast.showToast(msg: "⚠️ Fields cannot be empty!");
                  return;
                }

                int updatedRateInt = int.tryParse(updatedRate) ?? 0;
                if (updatedRateInt == 0) {
                  Fluttertoast.showToast(
                    msg: "⚠️ Sell Rate must be a valid number!",
                  );
                  return;
                }
                String updatedNameLower = updatedName.toLowerCase();
                // ✅ Check if either name or rate is changed
                if (updatedNameLower == oldName.toLowerCase() &&
                    updatedRateInt == oldRate) {
                  Navigator.pop(context); // ✅ Close popup
                  Fluttertoast.showToast(msg: "⚠️ No changes made!");
                  return;
                }
                List<String> lowerCaseProducts =
                    productList
                        .map((p) => (p['product_name'] as String).toLowerCase())
                        .toList();

                if (lowerCaseProducts.contains(updatedNameLower) &&
                    updatedNameLower != oldName.toLowerCase()) {
                  Fluttertoast.showToast(
                    msg: "⚠️ Product '$updatedName' already exists!",
                  );
                  return;
                }

                try {
                  await supabase
                      .from('products')
                      .update({
                        'product_name': updatedName,
                        'product_rate': updatedRateInt,
                      })
                      .eq('id', filteredList[index]['id']); // ✅ Update using ID
                  Fluttertoast.showToast(
                    msg: "✅ Product updated successfully!",
                  );
                  await _syncFromSupabase();
                  Navigator.pop(context);
                } catch (e) {
                  print("❌ Error updating product: $e");
                  Fluttertoast.showToast(msg: "⚠️ Error updating product.");
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

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
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      filteredList[index]['product_name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "₹${filteredList[index]['product_rate']}",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    leading: Icon(Icons.shopping_cart, color: Colors.blue),
                    trailing:
                        isOnline
                            ? IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _editProduct(index),
                            )
                            : Icon(Icons.lock, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          isOnline
              ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: _showAddProductDialog,
              )
              : null,
    );
  }
}
