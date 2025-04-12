import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:drop_down_list/drop_down_list.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/printersetup.dart';

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
  final supabase = Supabase.instance.client;

  final GlobalKey<FormFieldState> multiSelectKey = GlobalKey<FormFieldState>();
  List<Map<String, dynamic>> recentSales = [];
  int currentPage = 1;
  int pageSize = 10;
  bool isLoading = false;
  List<Map<String, dynamic>> salesEntries = [];
  String searchQuery = "";
  String? selectedPartyName;
  String? selectedPrinter;

  @override
  void initState() {
    super.initState();
    isLoading = true; // ✅ Set loading state before fetching data
    _loadData().then((_) {
      setState(() {
        isLoading = false; // ✅ Update state only after data is loaded
      });
    });
    _fetchRecentSales();
    _generateInvoiceNo();
  }

  Future<void> _loadData() async {
    try {
      final partyResponse = await supabase.from('parties').select();
      final productResponse = await supabase.from('product_head').select();
      final priceResponse = await supabase.from('pricelist').select();

      setState(() {
        partyList =
            partyResponse.map<String>((p) {
              String fullPartyName = p['partyname'].toString();
              partyMap[fullPartyName] = p['id'].toString();
              return fullPartyName;
            }).toList();
        partyList.sort(); // Sort alphabetically
        isLoading = false;
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
      isLoading = false;
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

  /*void _editEntry(Map<String, dynamic> entry) {
    TextEditingController qtyController = TextEditingController(
      text: entry['quantity'].toString(),
    );
    TextEditingController rateController = TextEditingController(
      text: entry['rate'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Sales Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Product: ${entry['product_name']}"),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(labelText: "Rate"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                int newQty =
                    int.tryParse(qtyController.text) ?? entry['quantity'];
                double newRate =
                    double.tryParse(rateController.text) ?? entry['rate'];
                double newAmount = newQty * newRate;

                await supabase
                    .from('sales_entries')
                    .update({
                      'quantity': newQty,
                      'rate': newRate,
                      'amount': newAmount,
                    })
                    .eq('id', entry['id']);

                Navigator.pop(context);
                setState(() {}); // Refresh UI
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }*/

  void _editInvoice(List<Map<String, dynamic>> invoiceEntries) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Invoice: ${invoiceEntries.first['invoiceno']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                invoiceEntries.map((entry) {
                  TextEditingController qtyController = TextEditingController(
                    text: entry['quantity'].toString(),
                  );
                  TextEditingController rateController = TextEditingController(
                    text: entry['rate'].toString(),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Product: ${entry['product_name']}"),
                      TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(
                          labelText: "Quantity",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: rateController,
                        decoration: const InputDecoration(labelText: "Rate"),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                for (var entry in invoiceEntries) {
                  int newQty =
                      int.tryParse(entry['quantity'].toString()) ??
                      entry['quantity'];
                  int newRate =
                      int.tryParse(entry['rate'].toString()) ?? entry['rate'];
                  int newAmount = newQty * newRate;

                  await supabase
                      .from('sales_entries')
                      .update({
                        'quantity': newQty,
                        'rate': newRate,
                        'amount': newAmount,
                      })
                      .eq('id', entry['id']);
                }

                Navigator.pop(context);
                setState(() {}); // Refresh UI
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
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

  void _showPartyDropDown(BuildContext context) {
    if (isLoading) {
      Fluttertoast.showToast(msg: "Loading parties, please wait...");
      return;
    }
    if (partyList.isEmpty) {
      Fluttertoast.showToast(msg: "Fetching Parties...Please Wait...");
      return;
    }
    List<SelectedListItem<String>> partyItems =
        partyList.map((party) {
          return SelectedListItem<String>(data: party);
        }).toList();

    DropDownState(
      dropDown: DropDown(
        data: partyItems,
        bottomSheetTitle: Text(
          "Select Party",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        isDismissible: true,
        searchHintText: "Search Party...",
        onSelected: (List<SelectedListItem<String>> selectedList) {
          if (selectedList.isNotEmpty) {
            String selectedName = selectedList.first.data;
            String selectedID = partyMap[selectedName] ?? "0";

            setState(() {
              selectedParty = selectedID;
              selectedPartyName = selectedName;
            });
            print(
              "🟢 Corrected Selection - Party ID: $selectedParty, Name: $selectedPartyName",
            );

            Future.microtask(() {
              setState(() {}); // ✅ Ensures UI rebuilds
            });
          }
        },
      ),
    ).showModal(context);
  }

  Future<void> _fetchRecentSales() async {
    try {
      final response = await supabase
          .from('sales_entries')
          .select('''
          id, date, invoiceno, 
          parties!inner(partyname), 
          product_head!inner(product_name), 
          quantity, rate, amount
        ''')
          .order('date', ascending: false);

      if (response != null && response.isNotEmpty) {
        setState(() {
          salesEntries =
              response.map<Map<String, dynamic>>((entry) {
                return {
                  'id': entry['id'].toString(),
                  'date': entry['date'].toString(),
                  'invoiceno': entry['invoiceno'].toString(),
                  'party_name': entry['parties']['partyname'].toString(),
                  'product_name':
                      entry['product_head']['product_name'].toString(),
                  'quantity': entry['quantity'].toString(),
                  'rate': entry['rate'].toString(),
                  'amount': entry['amount'].toString(),
                };
              }).toList();
        });
      } else {
        print('No sales entries found.');
      }
    } catch (e) {
      print('Error fetching recent sales: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch recent sales: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    String? printerIP = prefs.getString('printer_ip');

    debugPrint("🔍 Loaded Printer IP in Sales Entry: $printerIP"); // Debug Log

    setState(() {
      selectedPrinter = printerIP;
    });
  }

  Future<void> printSalesChallan(
    String invoiceNo,
    String partyName,
    List<Map<String, dynamic>> products,
    double totalAmount,
  ) async {
    if (selectedPrinter == null || selectedPrinter!.isEmpty) {
      Fluttertoast.showToast(
        msg: "No printer configured. Please set up a printer first.",
      );
      return;
    }
    debugPrint("🖨️ Printing to: $selectedPrinter"); // Debug Log

    try {
      var parts = selectedPrinter!.split(':');
      String ip = parts[0];
      int port = parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100;

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Printer initialization
      bytes += generator.reset();
      bytes += generator.setGlobalCodeTable('CP1252');

      bytes += generator.text(
        "SALES CHALLAN",
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        "Invoice: $invoiceNo",
        styles: PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        "Party: $partyName",
        styles: PosStyles(align: PosAlign.left),
      );
      bytes += generator.hr();

      for (var product in products) {
        bytes += generator.text(
          "${product['name']} x${product['quantity']}   Rs.${product['price']}",
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          "Rs.${(int.parse(product['quantity']) * int.parse(product['price']))}",
          styles: PosStyles(align: PosAlign.right),
        );
      }

      bytes += generator.hr();
      bytes += generator.text(
        "Total: Rs.$totalAmount",
        styles: PosStyles(
          align: PosAlign.right,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      final printer = PrinterNetworkManager(
        ip,
        port: port,
        timeout: Duration(seconds: 10),
      );
      debugPrint("🔌 Attempting to connect to printer...");

      final PosPrintResult res = await printer.connect();

      if (res == PosPrintResult.success) {
        debugPrint("✅ Connected successfully, sending print job...");
        await printer.printTicket(bytes);
        debugPrint("✅ Print job sent successfully.");

        Fluttertoast.showToast(msg: "Print job sent to printer");
      } else {
        debugPrint("❌ Connection failed: ${res.msg}");

        Fluttertoast.showToast(msg: "Printer error: ${res.msg}");
      }
      await printer.disconnect();
      debugPrint("🔌 Disconnected from printer");
    } catch (e) {
      debugPrint("‼️ Print error: $e");

      Fluttertoast.showToast(msg: "Print error: ${e.toString()}");
    }
  }

  Future<void> printTestReceipt() async {
    if (selectedPrinter == null || selectedPrinter!.isEmpty) {
      Fluttertoast.showToast(
        msg: "❌ No printer configured. Please set up a printer first.",
      );
      return;
    }

    debugPrint("🖨️ Sending TEST receipt to: $selectedPrinter");

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text(
        "**TEST PRINT**",
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.hr();
      bytes += generator.text(
        "Hello from Flutter!",
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3); // Add empty lines for spacing
      bytes += generator.cut();

      final printer = PrinterNetworkManager(
        selectedPrinter!,
        port: 9100,
        timeout: Duration(seconds: 10),
      );
      final PosPrintResult res = await printer.connect();

      if (res == PosPrintResult.success) {
        await printer.printTicket(bytes);
        Fluttertoast.showToast(msg: "✅ Test print successful");
        debugPrint("✅ Test print job sent successfully.");
      } else {
        Fluttertoast.showToast(msg: "⚠️ Printer error: ${res.msg}");
        debugPrint("⚠️ Printer connection error: ${res.msg}");
      }

      await printer.disconnect();
    } catch (e) {
      debugPrint("❌ Test print error: ${e.toString()}");
      Fluttertoast.showToast(msg: "❌ Test print error: ${e.toString()}");
    }
  }

  /* void showPrinterSetupDialog(BuildContext context) async {
    TextEditingController ipController = TextEditingController();
    String? detectedIp = await findPrinterIP();

    if (detectedIp != null) {
      ipController.text = detectedIp;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Printer Setup"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Printer IP:"),
              TextField(
                controller: ipController,
                decoration: InputDecoration(hintText: "e.g., 192.168.1.100"),
              ),
              SizedBox(height: 10),
              Text("Detected IP: ${detectedIp ?? 'Not found'}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String enteredIp = ipController.text.trim();
                if (await tryConnectPrinter(enteredIp)) {
                  await savePrinterIP(enteredIp);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: "Printer IP saved.");
                } else {
                  Fluttertoast.showToast(msg: "Invalid IP, try again.");
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
*/
  double _dividerPosition = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Entry'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            tooltip: "Setup Printer",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrinterSetupScreen()),
              ).then((_) {
                debugPrint("📢 Returning from Printer Setup Screen...");
                _loadSavedPrinter(); // Reload printer IP
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(),
                ) // ✅ Show loader while fetching data
                : Column(
                  children: [
                    Expanded(
                      flex: (_dividerPosition * 100).toInt(),

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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap:
                                  isLoading || partyList.isEmpty
                                      ? () => Fluttertoast.showToast(
                                        msg: "Loading parties, please wait...",
                                      )
                                      : () => _showPartyDropDown(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedPartyName ??
                                          "Select Party", // ✅ Show Name, Not ID
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            /*  // Party Selection
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
                    ),*/
                            const SizedBox(height: 10),

                            // Product Multi-Select
                            MultiSelectDialogField(
                              initialValue:
                                  selectedProducts.isEmpty
                                      ? []
                                      : selectedProducts, // Ensure reset
                              items:
                                  productList
                                      .map((p) => MultiSelectItem(p, p))
                                      .toList(),
                              title: const Text("Select Products"),
                              buttonText: const Text("Choose Products"),
                              onConfirm: (values) {
                                setState(() {
                                  selectedProducts = values.cast<String>();
                                  for (var product in selectedProducts) {
                                    qtyControllers[product] ??=
                                        TextEditingController();
                                    rateControllers[product] ??=
                                        TextEditingController();
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
                                              controller:
                                                  qtyControllers[productName],
                                              decoration: const InputDecoration(
                                                labelText: "Qty",
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged:
                                                  (_) => _calculateAmount(
                                                    productName,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 80,
                                            child: TextFormField(
                                              controller:
                                                  rateControllers[productName],
                                              decoration: InputDecoration(
                                                labelText: "Rate",
                                                filled: true,
                                                fillColor:
                                                    rateFieldColor[productName] ??
                                                    Colors.white, // Apply color
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged:
                                                  (_) => _calculateAmount(
                                                    productName,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 80,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                            ElevatedButton(
                              onPressed:
                                  () => printSalesChallan(
                                    invoiceNo,
                                    selectedParty ?? "",
                                    selectedProducts
                                        .map(
                                          (product) => {
                                            'name': product,
                                            'quantity':
                                                qtyControllers[product]?.text ??
                                                '0',
                                            'price':
                                                rateControllers[product]
                                                    ?.text ??
                                                '0',
                                          },
                                        )
                                        .toList(),
                                    amounts.values
                                        .fold(0, (sum, amount) => sum + amount)
                                        .toDouble(),
                                  ),
                              child: const Text("Print Sales Challan"),
                            ),
                            ElevatedButton(
                              onPressed:
                                  () =>
                                      printTestReceipt(), // Change to printRawText() if needed
                              child: Text("Print Test Receipt"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    /*
            // Adjustable Divider
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  // Update the divider position based on drag movement
                  _dividerPosition +=
                      details.delta.dy / MediaQuery.of(context).size.height;
                  // Clamp the value between 0.2 and 0.8 to prevent extreme sizes
                  _dividerPosition = _dividerPosition.clamp(0.2, 0.8);
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown, // Show resize cursor
                child: Container(
                  height: 10,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.drag_handle, size: 20)),
                ),
              ),
            ),
            // Recent Sales Section
            Expanded(
              flex: ((1 - _dividerPosition) * 100).toInt(),
              child: _buildSalesEntriesList(),
            ),*/
                  ],
                ),
      ),
    );
  }

  // ✅ Function to Fetch and Display Sales Entries
  Widget _buildSalesEntriesList() {
    return FutureBuilder(
      future: supabase
          .from('sales_entries')
          .select('''
          id, date, invoiceno, 
          parties!inner(partyname), 
          product_head!inner(product_name), 
          quantity, rate, amount
        ''')
          .order('id', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No sales entries found.'));
        }
        // Grouping sales entries by invoice number
        Map<String, List<Map<String, dynamic>>> groupedEntries = {};

        for (var entry in snapshot.data as List) {
          String invoiceNo = entry['invoiceno'].toString();
          if (!groupedEntries.containsKey(invoiceNo)) {
            groupedEntries[invoiceNo] = [];
          }
          groupedEntries[invoiceNo]!.add(entry);
        }
        /*List<Map<String, dynamic>> salesEntries =
            (snapshot.data as List).map((entry) {
              return {
                'id': entry['id'],
                'date': entry['date'],
                'invoiceno': entry['invoiceno'],
                'party_name': entry['parties']['partyname'],
                'product_name': entry['products']['product_name'],
                'quantity': entry['quantity'],
                'rate': entry['rate'],
                'amount': entry['amount'],
              };
            }).toList();*/

        return ListView.builder(
          itemCount: groupedEntries.length,
          itemBuilder: (context, index) {
            String invoiceNo = groupedEntries.keys.elementAt(index);
            List<Map<String, dynamic>> invoiceEntries =
                groupedEntries[invoiceNo]!;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Header (Party Name & Date)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${invoiceEntries.first['parties']?['partyname']?.toString()} - ${invoiceEntries.first['date'].toString()}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editInvoice(invoiceEntries),
                        ),
                      ],
                    ),

                    const Divider(),

                    // Product List within Invoice
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          invoiceEntries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "${entry['product_head']?['product_name'].toString()} | Qty: ${entry['quantity'].toString()} | Rate: ₹${entry['rate'].toString()} | Amount: ₹${entry['amount'].toString()}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
