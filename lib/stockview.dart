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

  Future<void> _fetchStock(String searchTerm) async {
    setState(() => _isLoading = true);
    final response = await Supabase.instance.client
        .from('stock')
        .select('product_head(product_name), quantity, locations(name)')
        .ilike('product_head.product_name', '%$searchTerm%')
        .order('product_head.product_name');
    
    setState(() {
      _stockData = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  Future<void> _addStock() async {
    final product = _productController.text;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final location = _locationController.text;

    if (product.isEmpty || quantity <= 0 || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid details!')),
      );
      return;
    }

    await Supabase.instance.client.from('stock').insert({
      'product_id': product,
      'quantity': quantity,
      'location_id': location,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stock added successfully!')),
    );

    _productController.clear();
    _quantityController.clear();
    _locationController.clear();
    Navigator.pop(context); // Close the bottom sheet
    _fetchStock('');
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
              Text("Add Stock", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: _productController, decoration: InputDecoration(labelText: "Design Number")),
              TextField(controller: _quantityController, decoration: InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
              TextField(controller: _locationController, decoration: InputDecoration(labelText: "Location")),
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Design Number',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _fetchStock(_searchController.text),
                ),
              ),
            ),
            SizedBox(height: 10),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _stockData.length,
                      itemBuilder: (context, index) {
                        final stock = _stockData[index];
                        return Card(
                          child: ListTile(
                            title: Text(stock['product_head']['product_name']),
                            subtitle: Text('Location: ${stock['locations']['name']}\nQuantity: ${stock['quantity']}'),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}
