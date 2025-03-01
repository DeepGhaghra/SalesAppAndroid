import 'dart:async';
import 'dart:io';
import 'utils/sync_utils.dart'; // Import sync utils
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/party_list.dart'; // Ensure this import is correct
import 'package:sales_app/product_list.dart';
import 'package:sales_app/pricelist.dart';
import 'package:search_choices/search_choices.dart'; // Import the package
import 'package:sales_app/ExportData.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bnvwbcndpfndzgcrsicc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJudndiY25kcGZuZHpnY3JzaWNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0Nzg4NzIsImV4cCI6MjA1NjA1NDg3Mn0.YDEmWHZnsVrgPbf71ytIVm4IrOf9xTqzthlhluW_OLI',
  );
  runApp(SalesEntryApp());
}

class SalesEntryApp extends StatelessWidget {
  const SalesEntryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Entry',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SalesEntryScreen(),
    );
  }
}

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({super.key});

  @override
  _SalesEntryScreenState createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  DateTime selectedDate = DateTime.now();
  String invoiceNo = '';
  String? selectedParty;
  String? selectedProduct;
  TextEditingController qtyController = TextEditingController();
  TextEditingController rateController = TextEditingController();

  int rate = 0;
  int amount = 0;
  List<String> partyList = [];
  List<String> productList = [];
  Map<String, Map<String, int>> priceList = {}; // {party: {product: rate}}
  Map<String, int> productRates = {}; // Base rates

  List<Map<String, dynamic>> savedEntries = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode partyFocusNode = FocusNode();
  final SupabaseClient supabase = Supabase.instance.client;
  late SharedPreferences prefs;
  String lastSyncTime = 'Never';
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    ConnectivityUtils.startInternetListening(() {
      setState(() {
        isOnline = true;
      });
    });
    _loadLastDate();
    _loadPartyList();
    _loadProductList();
    _loadPriceList();
    _generateInvoiceNo();
    initializeApp();
  }

  @override
  void dispose() {
    ConnectivityUtils.dispose(); // ✅ Properly dispose the listener
    super.dispose();
  }

  Future<void> initializeApp() async {
    prefs = await SharedPreferences.getInstance();
    lastSyncTime = prefs.getString('last_sync') ?? 'Never';
    await fetchDataFromSupabase();
  }

  Future<void> fetchDataFromSupabase() async {
    try {
      final partyResponse = await supabase.from('parties').select();
      final productResponse = await supabase.from('product_list').select();
      final priceResponse = await supabase.from('price_list').select();

      await prefs.setString('parties', partyResponse.toString());
      await prefs.setString('product_list', productResponse.toString());
      await prefs.setString('price_list', priceResponse.toString());

      lastSyncTime = DateTime.now().toString();
      await prefs.setString('last_sync', lastSyncTime);
      setState(() {});
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _loadPartyList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      partyList = prefs.getStringList('parties') ?? [];
    });
  }

  Future<void> _loadProductList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      productList = prefs.getStringList('product_list') ?? [];
    });
  }

  Future<void> _loadPriceList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? priceListJson = prefs.getString('price_list');
    String? productRatesJson = prefs.getString('product_rates');
    print('Raw priceList JSON: $priceListJson');
    print('Raw productRates JSON: $productRatesJson');
    if (priceListJson != null) {
      setState(() {
        priceList = Map<String, Map<String, int>>.from(
          jsonDecode(
            priceListJson,
          ).map((key, value) => MapEntry(key, Map<String, int>.from(value))),
        );
      });
    }

    if (productRatesJson != null) {
      setState(() {
        productRates = Map<String, int>.from(jsonDecode(productRatesJson));
      });
    }
    print("Loaded priceList: $priceList"); // Debugging
    print("Loaded productRates: $productRates"); // Debugging
  }

  Future<void> _loadLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastDate');
    if (lastDate != null) {
      setState(() {
        selectedDate = DateTime.parse(lastDate);
      });
    }
  }

  Future<void> _saveLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDate', selectedDate.toIso8601String());
  }

  Future<void> _generateInvoiceNo() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usedInvoiceNumbers =
        prefs.getStringList('usedInvoiceNumbers') ?? [];

    String datePrefix = DateFormat('ddMM').format(selectedDate);
    int counter = 1;

    // Generate a new invoice number ensuring uniqueness
    while (usedInvoiceNumbers.contains(
      '$datePrefix${counter.toString().padLeft(2, '0')}',
    )) {
      counter++;
    }

    invoiceNo = '$datePrefix${counter.toString().padLeft(2, '0')}';

    // Save the new invoice number
    usedInvoiceNumbers.add(invoiceNo);
    await prefs.setStringList('usedInvoiceNumbers', usedInvoiceNumbers);

    setState(() {});
  }

  void _updateRate() {
    if (selectedParty != null && selectedProduct != null) {
      setState(() {
        // Try fetching the rate from the price list
        int? partySpecificRate = priceList[selectedParty]?[selectedProduct];
        int? baseRate = productRates[selectedProduct]; // Base selling price
        // Debugging prints
        print("Selected Party: $selectedParty");
        print("Selected Product: $selectedProduct");
        print("Party-Specific Rate: $partySpecificRate");
        print("Base Selling Price: $baseRate");
        if (partySpecificRate != null) {
          rate = partySpecificRate; // Use party-specific rate if available
        } else if (baseRate != null) {
          rate = baseRate; // Use base selling price
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No rate found for this party. Using base rate: ₹$rate. Please update if needed.",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          rate = 0; // If no rate is found at all, default to 0
        }

        rateController.text = rate.toString();
        amount = rate * (int.tryParse(qtyController.text) ?? 0);
      });
    }
  }

  void _editEntry(int index) {
    // Get the selected entry
    var entry = savedEntries[index];

    // Populate the form fields with the entry's data
    setState(() {
      selectedDate = DateFormat('dd/MM/yyyy').parse(entry['date']);
      invoiceNo = entry['invoice'];
      selectedParty = entry['party'];
      selectedProduct = entry['product'];
      qtyController.text = entry['qty'];
      rate = entry['rate'];
      amount = entry['amount'];
    });

    // Remove the old entry from the list
    setState(() {
      savedEntries.removeAt(index);
    });

    // Move focus to the Party Name field
    FocusScope.of(context).requestFocus(partyFocusNode);
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        savedEntries.add({
          'date': DateFormat('dd/MM/yyyy').format(selectedDate),
          'invoice': invoiceNo,
          'party': selectedParty,
          'product': selectedProduct,
          'qty': qtyController.text,
          'rate': rate,
          'amount': amount,
        });

        // Reset fields after saving
        selectedParty = null;
        selectedProduct = null;
        qtyController.clear();
        rate = 0;
        amount = 0;
        _generateInvoiceNo();

        // Move focus to the Party Name field
        FocusScope.of(context).requestFocus(partyFocusNode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales Entry')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 28),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Last Sync: $lastSyncTime',
                    style: TextStyle(
                      color: Colors.grey[200],
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text("Party List"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PartyListScreen(isOnline: isOnline,)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text("Product List"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductListScreen(isOnline: isOnline,)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.price_check),
              title: Text("Price List"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PriceListScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text("Export Data"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExportDataScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Date'),
                controller: TextEditingController(
                  text: DateFormat('dd/MM/yyyy').format(selectedDate),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                      _saveLastDate();
                      _generateInvoiceNo();
                    });
                  }
                },
              ),
              Text("Invoice No: $invoiceNo"),
              //Searchable Text for Product name
              SearchChoices.single(
                items:
                    partyList.map((party) {
                      return DropdownMenuItem(value: party, child: Text(party));
                    }).toList(),
                value: selectedParty,
                hint: "Select Party",
                searchHint: "Search for a party",

                onChanged: (value) {
                  setState(() {
                    selectedParty = value;
                    print("Selected Party Changed: $selectedParty");

                    _updateRate();
                  });
                },
                isExpanded: true,
                dialogBox: true, // Use dialog mode
                selectedValueWidgetFn: (item) {
                  return Text(item?.toString() ?? '');
                },
              ),
              DropdownButtonFormField(
                value: selectedProduct,
                items:
                    productList
                        .map(
                          (product) => DropdownMenuItem(
                            value: product,
                            child: Text(product),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProduct = value;
                    print("Selected Product Changed: $selectedProduct");

                    _updateRate();
                  });
                },
                decoration: InputDecoration(labelText: "Product Name"),
              ),
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity cannot be empty';
                  }
                  if (int.tryParse(value) == 0) {
                    return 'Quantity must be greater than zero';
                  }
                  return null;
                },
                onChanged: (value) => _updateRate(),
              ),
              Text("Rate: ₹${rate.toString()}"),
              Text("Amount: ₹${amount.toString()}"),
              ElevatedButton(onPressed: _saveEntry, child: Text('Save Entry')),

              Expanded(
                child:
                    savedEntries.isEmpty
                        ? const Center(
                          child: Text(
                            'No entries yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: ListView.builder(
                            itemCount: savedEntries.length,
                            itemBuilder: (context, index) {
                              var entry = savedEntries[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                elevation: 6,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(
                                      entry['qty'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    entry['party'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Product: ${entry['product']}'),
                                      Text('Rate: ₹${entry['rate']}'),
                                      Text(
                                        'Amount: ₹${entry['amount']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _editEntry(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            savedEntries.removeAt(index);
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Entry deleted: ${entry['party']}',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
