import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:search_choices/search_choices.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({super.key});

  @override
  _SalesEntryScreenState createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  DateTime selectedDate = DateTime.now();
  String invoiceNo = '1000';
  String? selectedParty;
  List<String> selectedProducts = [];
  TextEditingController qtyController = TextEditingController();
  Map<String, TextEditingController> qtyControllers = {};
  Map<String, TextEditingController> rateControllers = {};
  Map<String, int> rates = {};
  Map<String, int> amounts = {};

  List<String> partyList = [];
  List<String> productList = [];
  Map<String, Map<String, int>> priceList = {}; // party -> {product: rate}
  Map<String, int> productRates = {}; // product -> base rate
  Map<String, String> partyMap = {}; // partyName -> partyID
  Map<String, String> productMap = {}; // productName -> productID
  Map<String, Color> rateFieldColor = {}; //rate field colour change

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<FormFieldState> multiSelectKey = GlobalKey<FormFieldState>();
  List<Map<String, dynamic>> recentSales = [];
  int currentPage = 1;
  int pageSize = 10;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchRecentSales();
    _generateInvoiceNo();
  }

  Future<void> _loadData() async {
    try {
      final partyResponse = await supabase.from('parties').select();
      final productResponse = await supabase.from('products').select();
      final priceResponse = await supabase.from('pricelist').select();

      setState(() {
        partyList =
            partyResponse.map<String>((p) {
              partyMap[p['partyname']] = p['id'].toString();
              return p['partyname'].toString();
            }).toList();
        partyList.sort(); // Sort alphabetically

        productList =
            productResponse.map<String>((p) {
              productMap[p['product_name']] = p['id'].toString();
              return p['product_name'].toString();
            }).toList();

        for (var product in productResponse) {
          productRates[product['product_name']] =
              product['product_rate']; // Store base rate
        }

        for (var price in priceResponse) {
          final partyId = price['party_id'].toString();
          final productId = price['product_id'].toString();
          final rate = price['price'];

          priceList[partyId] ??= {}; // Initialize if not exists
          priceList[partyId]![productId] = rate;
        }
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _generateInvoiceNo() {
    setState(() {
      invoiceNo = '1000${DateTime.now().millisecondsSinceEpoch % 1000}';
    });
  }

  void _updateRate(String product) {
    setState(() {
      String? productId = productMap[product]; // Ensure correct ID

      int? partySpecificRate = priceList[selectedParty]?[productId];
      int? baseRate = productRates[product];

      if (partySpecificRate != null) {
        rates[product] = partySpecificRate;
        rateFieldColor[product] = Colors.white; // Reset if custom rate
        // Fluttertoast.showToast(msg: "Enter PArty's rate");
      } else if (baseRate != null) {
        rates[product] = baseRate;
        rateControllers[product]!.text = baseRate.toString();
        rateFieldColor[product] = const Color.fromARGB(
          255,
          220,
          237,
          246,
        ); // Change field color
      } else {
        rates[product] = 0;
      }

      rateControllers[product]!.text = rates[product]!.toString();
      _calculateAmount(product);
    });
  }

  void _calculateAmount(String product) {
    setState(() {
      int qty = int.tryParse(qtyControllers[product]?.text ?? '0') ?? 0;
      int rate = int.tryParse(rateControllers[product]?.text ?? '0') ?? 0;
      amounts[product] = qty * rate;
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedParty == null) {
      Fluttertoast.showToast(msg: "Please select a party!");
      return;
    }

    if (selectedProducts.isEmpty) {
      Fluttertoast.showToast(msg: "Please select at least one product!");
      return;
    }
    final existingInvoice =
        await supabase
            .from('sales_entries')
            .select('id') // Selecting ID is enough for checking existence
            .eq('invoiceno', invoiceNo)
            .maybeSingle();

    if (existingInvoice != null) {
      _generateInvoiceNo();
      _saveEntry();
      return;
    }
    List<Map<String, dynamic>> salesData = [];
    String timestamp = DateTime.now().toUtc().toIso8601String();
    try {
      for (var product in selectedProducts) {
        String? productId = productMap[product]; // Get product ID
        if (productId == null) continue; // Skip if ID not found

        int qty = int.tryParse(qtyControllers[product]!.text) ?? 0;
        int rate = int.tryParse(rateControllers[product]!.text) ?? 0;
        int amount = qty * rate;

        if (qty == 0 || rate == 0) {
          Fluttertoast.showToast(
            msg:
                "Invalid entry for $product. Quantity and Rate must be greater than 0.",
          );
          return;
        }
        salesData.add({
          'date': DateFormat('dd-MM-yyyy').format(selectedDate),
          'invoiceno': invoiceNo,
          'party_id': int.parse(selectedParty!),
          'product_id': int.parse(productId),
          'quantity': qty,
          'rate': rate,
          'amount': amount,
          'created_at': timestamp,
          'modified_at': timestamp,
        });

        // Insert missing price into pricelist
        if (!priceList.containsKey(selectedParty) ||
            !priceList[selectedParty]!.containsKey(productId)) {
          await supabase.from('pricelist').insert({
            'party_id': int.parse(selectedParty!),
            'product_id': int.parse(productId),
            'price': rate,
          });
        }
      }

      await supabase.from('sales_entries').insert(salesData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sales Entry Saved!"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _generateInvoiceNo();
        selectedParty = null;
        selectedProducts = [];
        qtyControllers.clear();
        rateControllers.clear();
        amounts.clear();
      });
    } catch (error) {
      debugPrint("Error saving entry: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save entry: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _fetchRecentSales() async {
    setState(() => isLoading = true);

    final response = await supabase
        .from('sales_entries')
        .select(
          'id, date, parties!inner(partyname), products!inner(product_name), quantity, rate',
        )
        .order('date', ascending: false)
        .range((currentPage - 1) * pageSize, currentPage * pageSize - 1);
    print(
      'Fetching entries from ${(currentPage - 1) * pageSize} to ${currentPage * pageSize - 1}',
    );
    print("Raw Response: $response"); // Debugging the actual response

    setState(() {
      recentSales = List.from(response);
      isLoading = false;
      print("recentSales length: ${recentSales.length}");
    });
  }

  void _editEntry(int entryId) async {
    var entry =
        await supabase
            .from('sales_entries')
            .select('*')
            .eq('id', entryId)
            .single();

    // Navigate to an Edit Page (or open a Dialog)
    /* Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEntryScreen(entry: entry)),
    );*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Date Selector
              ListTile(
                title: Text(
                  "Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ),

              // Invoice Number (Read-Only)
              ListTile(
                title: Text(
                  "Invoice No: $invoiceNo",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Party Selection
              SearchChoices.single(
                items:
                    partyList
                        .map(
                          (p) => DropdownMenuItem(
                            value: partyMap[p],
                            child: Text(p),
                          ),
                        )
                        .toList(),
                value: selectedParty,
                hint: "Select Party",
                onChanged: (value) {
                  setState(() {
                    selectedParty = value;
                    selectedProducts.clear();
                  });
                },
                isExpanded: true,
              ),

              const SizedBox(height: 10),

              // Product Multi-Select
              MultiSelectDialogField(
                initialValue:
                    selectedProducts.isEmpty
                        ? []
                        : selectedProducts, // Ensure reset
                items: productList.map((p) => MultiSelectItem(p, p)).toList(),
                title: const Text("Select Products"),
                buttonText: const Text("Choose Products"),
                onConfirm: (values) {
                  setState(() {
                    selectedProducts = values.cast<String>();
                    for (var product in selectedProducts) {
                      qtyControllers[product] ??= TextEditingController();
                      rateControllers[product] ??= TextEditingController();
                      _updateRate(product);
                    }
                  });
                },
              ),

              const SizedBox(height: 10),

              // Product Entries
              Column(
                children:
                    selectedProducts.map((productName) {
                      return ListTile(
                        title: Text(productName),
                        subtitle: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: qtyControllers[productName],
                                decoration: const InputDecoration(
                                  labelText: "Qty",
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _calculateAmount(productName),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: rateControllers[productName],
                                decoration: InputDecoration(
                                  labelText: "Rate",
                                  filled: true,
                                  fillColor:
                                      rateFieldColor[productName] ??
                                      Colors.white, // Apply color
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _calculateAmount(productName),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Amount",
                                    style: TextStyle(
                                      fontSize: 12,
                                      //fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "₹ ${amounts[productName] ?? 0}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveEntry,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
