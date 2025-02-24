import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceListScreen extends StatefulWidget {
  @override
  _PriceListScreenState createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  Map<String, Map<String, double>> priceList = {}; // {party: {product: rate}}
  List<String> partyList = [];
  List<String> productList = [];
  String? selectedParty;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPriceList();
  }

  Future<void> _loadPriceList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load parties
      partyList = prefs.getStringList('party_list') ?? [];
      productList = prefs.getStringList('product_list') ?? [];
      
      // Load price list data
      for (String party in partyList) {
        priceList[party] = {};
        for (String product in productList) {
          String key = 'price_${party}_$product';
          double rate = prefs.getDouble(key) ?? 0.0; // Fetch price, fallback to 0
          priceList[party]![product] = rate;
        }
      }
    });
  }

  Future<void> _savePrice(String party, String product, double rate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('price_${party}_$product', rate);
  }

  void _updatePrice(String product, String party) {
    TextEditingController rateController = TextEditingController(
      text: priceList[party]?[product]?.toString() ?? '0.0',
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Price for $product"),
          content: TextField(
            controller: rateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Enter new price"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                double newRate = double.tryParse(rateController.text) ?? 0.0;
                setState(() {
                  priceList[party]?[product] = newRate;
                });
                _savePrice(party, product, newRate);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Price List")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              hint: Text("Select Party"),
              value: selectedParty,
              isExpanded: true,
              onChanged: (value) => setState(() => selectedParty = value),
              items: partyList.map((party) => DropdownMenuItem(
                value: party, child: Text(party),
              )).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search Product",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) => setState(() {}),
            ),
          ),
          Expanded(
            child: selectedParty == null
                ? Center(child: Text("Select a party to view rates"))
                : ListView(
                    children: productList
                        .where((product) => product.toLowerCase().contains(searchController.text.toLowerCase()))
                        .map((product) => Card(
                              child: ListTile(
                                title: Text(product),
                                subtitle: Text("Rate: ₹${priceList[selectedParty]?[product]?.toStringAsFixed(2) ?? '0.00'}"),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _updatePrice(product, selectedParty!),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
