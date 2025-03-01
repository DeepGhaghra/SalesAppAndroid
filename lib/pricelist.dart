import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  _PriceListScreenState createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> fullProductList = []; // All products
  Map<int, dynamic> partyPrices = {}; // Product prices for selected party
  TextEditingController _partyController = TextEditingController();
  final FocusNode _partyFocusNode = FocusNode();
  List<String> partySuggestions = [];
  bool isFetchingPrices = false;
  bool isUserTyping = false; // ✅ Track if user is typing
  String? selectedPartyId;

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
    _partyFocusNode.addListener(() {
      if (!_partyFocusNode.hasFocus) {
        setState(
          () => partySuggestions.clear(),
        ); // ✅ Clear suggestions when field loses focus
      }
    });
  }

  Future<void> _fetchAllProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select('id, product_name')
          .order('product_name', ascending: true);
      setState(() {
        fullProductList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("❌ Error fetching products: $e");
    }
  }

  Future<void> _fetchPartySuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => partySuggestions.clear());
      return;
    }
    setState(() => isUserTyping = true);

    try {
      final response = await supabase
          .from('parties')
          .select('partyname')
          .ilike('partyname', '%$query%') // Case-insensitive search
          .limit(5); // Show top 5 results

      setState(() {
        partySuggestions = List<String>.from(
          response.map((p) => p['partyname']),
        );
      });
    } catch (e) {
      print("❌ Error fetching party suggestions: $e");
    }
  }

  Future<void> _fetchPartyPrices(String partyName) async {
    if (isFetchingPrices) return; // ✅ Prevent duplicate API calls
    setState(() {
      isFetchingPrices = true;
      isUserTyping = false; // ✅ Stop suggestions after selection
    });
    try {
      final partyResponse =
          await supabase
              .from('parties')
              .select('id')
              .eq('partyname', partyName)
              .maybeSingle();

      if (partyResponse == null) {
        Fluttertoast.showToast(msg: "⚠️ Party not found!");
        return;
      }

      int? partyIdInt = partyResponse['id'] as int?;
      if (partyIdInt == null) {
        Fluttertoast.showToast(msg: "⚠️ Invalid party selection!");
        return;
      }
      selectedPartyId = partyIdInt.toString();

      final response = await supabase
          .from('pricelist')
          .select('product_id, price')
          .eq('party_id', partyIdInt);

      setState(() {
        partyPrices = {
          for (var item in response) item['product_id']: item['price'],
        };
        isFetchingPrices = false;
        partySuggestions.clear(); // ✅ Instantly clear suggestions
      });

      print("✅ Loaded ${partyPrices.length} prices for party: $partyName");
    } catch (e) {
      print("❌ Error fetching price list: $e");
    }
  }

  void _showEditPriceDialog(int productId, String productName) {
    TextEditingController priceController = TextEditingController(
      text: partyPrices[productId]?.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Price for $productName"),
          content: TextField(
            controller: priceController,
            decoration: InputDecoration(labelText: "Enter New Price"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePrice(productId, priceController.text.trim());
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePrice(int productId, String newPrice) async {
    if (newPrice.isEmpty) {
      Fluttertoast.showToast(msg: "⚠️ Price cannot be empty!");
      return;
    }

    int priceInt = int.tryParse(newPrice) ?? 0;
    if (priceInt == 0) {
      Fluttertoast.showToast(msg: "⚠️ Enter a valid price!");
      return;
    }
    int? partyIdInt = int.tryParse(selectedPartyId ?? '');
    if (partyIdInt == null) {
      Fluttertoast.showToast(msg: "⚠️ Invalid party selection!");
      return;
    }
    try {
      if (partyPrices.containsKey(productId)) {
        await supabase.from('pricelist').update({'price': priceInt}).match({
          'party_id': partyIdInt,
          'product_id': productId,
        });
      } else {
        await supabase.from('pricelist').insert({
          'party_id': partyIdInt,
          'product_id': productId,
          'price': priceInt,
        });
      }

      Fluttertoast.showToast(msg: "✅ Price updated successfully!");
      Navigator.pop(context);
      _fetchPartyPrices(_partyController.text);
    } catch (e) {
      print("❌ Error updating price: $e");
      Fluttertoast.showToast(msg: "⚠️ Error updating price.");
    }
  }

  Widget _buildPartySearchField() {
    return Column(
      children: [
        TextField(
          controller: _partyController,
          focusNode: _partyFocusNode,
          decoration: InputDecoration(
            labelText: "Search by Party Name",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onTap: () {
            if (!isUserTyping) {
              setState(
                () => partySuggestions.clear(),
              ); // ✅ Prevent suggestions on tap
            }
          },
          onChanged: (query) => _fetchPartySuggestions(query),
        ),
        if (partySuggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children:
                  partySuggestions.map((party) {
                    return ListTile(
                      title: Text(party),
                      onTap: () {
                        setState(() {
                          _partyController.text = party;
                          partySuggestions
                              .clear(); // ✅ Instantly clear suggestions
                          isUserTyping = false;
                        });
                        _partyFocusNode.unfocus(); // ✅ Close keyboard instantly
                        _fetchPartyPrices(party);
                      },
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Price List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildPartySearchField(),
          ),
          Expanded(
            child:
                fullProductList.isEmpty
                    ? Center(child: Text("No products found in database."))
                    : ListView.builder(
                      itemCount: fullProductList.length,
                      itemBuilder: (context, index) {
                        int productId = fullProductList[index]['id'];
                        String productName =
                            fullProductList[index]['product_name'];
                        String priceText =
                            partyPrices.containsKey(productId)
                                ? "₹${partyPrices[productId]}"
                                : "Not Set";

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              productName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              priceText,
                              style: TextStyle(
                                color:
                                    priceText == "Not Set"
                                        ? Colors.red
                                        : Colors.green,
                                fontSize: 16,
                              ),
                            ),
                            leading: Icon(
                              Icons.price_change,
                              color: Colors.blue,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                _showEditPriceDialog(productId, productName);
                              },
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
