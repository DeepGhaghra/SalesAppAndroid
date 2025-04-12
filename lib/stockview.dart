import 'package:flutter/material.dart';
import 'package:sales_app/utils/stocktransfer.dart';
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

  List<Map<String, dynamic>> _allStockData = [];
  List<Map<String, dynamic>> _filteredStockData = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 100; // Fetch in chunks

  @override
  void initState() {
    super.initState();
    _fetchInitialStock();
    _searchController.addListener(_filterStock);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStock);
    super.dispose();
  }

  Future<void> _fetchInitialStock() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stock')
          .select(
            'products_design:design_id(design_no), locations:location_id(name), quantity',
          )
          .order('design_id', ascending: true)
          .range(0, _pageSize - 1);

      setState(() {
        _allStockData = List<Map<String, dynamic>>.from(response);
        _filteredStockData = List.from(_allStockData);
        _isLoading = false;
        _currentPage = 1;
        _hasMore = response.length == _pageSize;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching stock: $e')));
    }
  }

  Future<void> _loadMoreStock() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stock')
          .select('''
            products_design:design_id(design_no), 
            locations:location_id(name), 
            quantity
          ''')
          .order('design_id', ascending: true)
          .range(_currentPage * _pageSize, (_currentPage + 1) * _pageSize - 1);

      setState(() {
        _allStockData.addAll(List<Map<String, dynamic>>.from(response));
        _filteredStockData = List.from(_allStockData);
        _isLoading = false;
        _currentPage++;
        _hasMore = response.length == _pageSize;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading more stock: $e')));
    }
  }

  void _filterStock() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredStockData = List.from(_allStockData));
      return;
    }

    setState(() {
      _filteredStockData =
          _allStockData.where((stock) {
            final designNo =
                stock['products_design']['design_no'].toString().toLowerCase();
            final location =
                stock['locations']['name'].toString().toLowerCase();
            return designNo.contains(query) || location.contains(query);
          }).toList();
    });
  }

  Future<void> _addStock() async {
    final productDesignNo = _productController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final locationName = _locationController.text.trim();

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

  void _navigateToStockTransfer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockTransferScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock View'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.swap_horiz,
              color: const Color.fromARGB(255, 141, 195, 204),
            ),
            onPressed: _navigateToStockTransfer,
            tooltip: "Stock Transfer",
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Design Number or Location...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // 📋 Stock List
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    !_isLoading &&
                    _hasMore) {
                  _loadMoreStock();
                }
                return false;
              },
              child:
                  _isLoading && _filteredStockData.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : _filteredStockData.isEmpty
                      ? Center(child: Text('No stock items found'))
                      : ListView.builder(
                        itemCount:
                            _filteredStockData.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _filteredStockData.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final stock = _filteredStockData[index];
                          final designNo =
                              stock['products_design']['design_no'];
                          final location = stock['locations']['name'];
                          final quantity = stock['quantity'];

                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  index % 2 == 0
                                      ? Colors.grey[100]
                                      : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color: Colors.blueGrey,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      designNo,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      location,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.inventory, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      "$quantity Qty",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockSheet,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
