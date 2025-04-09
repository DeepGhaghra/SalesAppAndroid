import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockViewScreen extends StatefulWidget {
  const StockViewScreen({super.key});

  @override
  _StockViewScreenState createState() => _StockViewScreenState();
}

class _StockViewScreenState extends State<StockViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _stockData = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _fetchStock(''); // Fetch stock data when the page loads
  }

  Future<void> _fetchStock(String searchTerm) async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stock')
          .select(
            'products_design:design_id(design_no), locations:location_id(name), quantity',
          )
          .order('design_id', ascending: true);

      print("Supabase Response: $response"); // Debugging line

      setState(() {
        _stockData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching stock: $e')));
    }
  }

  Future<void> _addStock() async {
    final productDesignNo = _productController.text;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final locationName = _locationController.text;

    if (productDesignNo.isEmpty || quantity <= 0 || locationName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter valid details!')));
      return;
    }
    try {
      // Fetch product ID from design number
      final productResponse =
          await Supabase.instance.client
              .from('products_design')
              .select('id')
              .eq('design_no', productDesignNo)
              .single();

      // Fetch location ID from location name
      final locationResponse =
          await Supabase.instance.client
              .from('locations')
              .select('id')
              .eq('name', locationName)
              .single();

      if (productResponse == null || locationResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid design number or location!')),
        );
        return;
      }

      final productId = productResponse['id'];
      final locationId = locationResponse['id'];

      await Supabase.instance.client.from('stock').insert({
        'design_id': productId,
        'quantity': quantity,
        'location_id': locationId,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stock added successfully!')));

      _productController.clear();
      _quantityController.clear();
      _locationController.clear();
      Navigator.pop(context); // Close the bottom sheet
      _fetchStock('');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding stock: $e')));
    }
  }

  void _showAddStockSheet() {
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
                controller: _productController,
                decoration: InputDecoration(labelText: "Design Number"),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: "Location"),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _addStock, child: Text("Add Stock")),
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
      body: Column(
        children: [
          // 🔎 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Design Number...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // 📋 Stock List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _stockData.length,
                    itemBuilder: (context, index) {
                      final stock = _stockData[index];
                      final designNo = stock['products_design']['design_no'];
                      final location = stock['locations']['name'];
                      final quantity = stock['quantity'];

                      // 🔎 Filter logic for search bar
                      if (_searchController.text.isNotEmpty &&
                          !designNo.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        return SizedBox.shrink(); // Hide if not matching search
                      }

                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.grey[100] : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 📌 Design Number
                            Row(
                              children: [
                                Icon(Icons.category, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text(
                                  designNo,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            // 📍 Location
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text(
                                  location,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),

                            // 📦 Quantity
                            Row(
                              children: [
                                Icon(Icons.inventory, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  "$quantity Qty",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ➕ Floating "Add Stock" Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Stock Page
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }}
