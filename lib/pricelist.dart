import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  _PriceListScreenState createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  Map<String, Map<String, int>> priceList = {}; // {party: {product: rate}}
  List<String> partyList = [];
  List<String> productList = [];
  List<String> filteredProducts = [];
  String? selectedParty;
  TextEditingController searchController = TextEditingController();
  TextEditingController partySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPriceList();
  }

  Future<void> _loadPriceList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      partyList = (prefs.getStringList('party_list') ?? [])..sort(); // Alphabetical order
      productList = prefs.getStringList('product_list') ?? [];
      filteredProducts = List.from(productList);

      for (String party in partyList) {
        priceList[party] = {};
        for (String product in productList) {
          String key = 'price_${party}_$product';
          int rate = prefs.getInt(key) ?? 0;
          priceList[party]![product] = rate;
        }
      }
    });
  }

  Future<void> _savePrice(String party, String product, int rate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('price_${party}_$product', rate);
  }

  void _updatePrice(String product, String party) {
    TextEditingController rateController = TextEditingController(
      text: priceList[party]?[product]?.toString() ?? '0',
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
                int newRate = int.tryParse(rateController.text) ?? 0;
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

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = productList
          .where((product) => product.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Price List")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return partyList
                    .where((party) => party.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                    .toList();
              },
              onSelected: (String value) {
                setState(() {
                  selectedParty = value;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                partySearchController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Search Party",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}), // Update search results
                );
              },
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
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: selectedParty == null
                ? Center(child: Text("Select a party to view rates"))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      String product = filteredProducts[index];
                      int rate = priceList[selectedParty]?[product] ?? 0;
                      return Card(
                        child: ListTile(
                          title: Text(product),
                          subtitle: Text("Rate: ₹$rate"),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updatePrice(product, selectedParty!),
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
