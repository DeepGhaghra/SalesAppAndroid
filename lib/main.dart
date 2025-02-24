import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/party_list.dart'; // Ensure this import is correct
import 'package:sales_app/product_list.dart';
import 'package:sales_app/pricelist.dart';
import 'package:search_choices/search_choices.dart'; // Import the package

void main() {
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
  double rate = 0.0;
  double amount = 0.0;
  List<String> partyList = [];
  List<String> productList = ['Product X', 'Product Y', 'Product Z'];
  Map<String, double> priceList = {
    'Party A-Product X': 100.0,
    'Party B-Product Y': 150.0,
    'Party C-Product Z': 200.0,
    'Party A-Product Z': 120.0,
    'Party C-Product X': 145.0,
  };
  List<Map<String, dynamic>> savedEntries = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode partyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadLastDate();
    _loadPartyList();
    _generateInvoiceNo();
  }

  Future<void> _loadPartyList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      partyList = prefs.getStringList('party_list') ?? [];
    });
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
        rate = priceList['$selectedParty-$selectedProduct'] ?? 0.0;
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
        rate = 0.0;
        amount = 0.0;
        _generateInvoiceNo();

        // Move focus to the Party Name field
        FocusScope.of(context).requestFocus(partyFocusNode);
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['SalesData'];
      sheet.appendRow([
        "Date",
        "Invoice No",
        "Party Name",
        "Product Name",
        "Quantity",
        "Rate",
        "Amount",
      ]);
      for (var entry in savedEntries) {
        sheet.appendRow([
          entry['date'],
          entry['invoice'],
          entry['party'],
          entry['product'],
          (int.tryParse(entry['qty']) ?? 0),
          (double.tryParse(entry['rate'].toString()) ?? 0.0),
          (double.tryParse(entry['amount'].toString()) ?? 0.0),
        ]);
      }

      String formattedDate = DateFormat('dd-MM').format(DateTime.now());
      String fileName = "salesentry-$formattedDate.xlsx";

      Directory directory = await getApplicationDocumentsDirectory();

      String filePath = "${directory.path}/$fileName";
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to $filePath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
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
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text("Party List"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PartyListScreen()),
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
                  MaterialPageRoute(builder: (context) => ProductListScreen()),
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
              ElevatedButton(
                onPressed: _exportToExcel,
                child: Text('Export to Excel'),
              ),
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
