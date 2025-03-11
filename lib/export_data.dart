import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  _ExportDataScreenState createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> salesEntries = [];
  Map<String, int> productSummary = {};

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchSalesData() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }
    try {
      final response = await supabase
          .from('sales_entries')
          .select(
            'date, invoiceno, quantity, rate, amount, parties (partyname), products (product_name)',
          )
          .gte('date', DateFormat('dd-MM-yyyy').format(startDate!))
          .lte('date', DateFormat('dd-MM-yyyy').format(endDate!))
          .order('date', ascending: true);
      Map<String, int> tempProductSummary = {};

      setState(() {
        salesEntries =
            response.map((entry) {
              String productName = entry['products']['product_name'];
              int quantity = entry['quantity'] ?? 0;

              tempProductSummary[productName] =
                  (tempProductSummary[productName] ?? 0) + quantity;
              return {
                'Date': entry['date'],
                'Invoice No': entry['invoiceno'],
                'Party': entry['parties']['partyname'],
                'Product': productName,
                'Quantity': quantity,
                'Rate': entry['rate'],
                'Amount': entry['amount'],
              };
            }).toList();
        productSummary = tempProductSummary;
      });
    } catch (e) {
      print('Error fetching sales data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data from Supabase')),
      );
    }
  }

  Future<void> _selectDateRange() async {
    DateTime today = DateTime.now();

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: today,
      initialDateRange:
          startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : DateTimeRange(start: today, end: today), // Default to today
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchSalesData();
    }
  }

  Future<void> _exportToExcel() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }
    if (salesEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No sales data available for export')),
      );
      return;
    }

    // Ask user where to save the file
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export cancelled or permission denied')),
      );
      return;
    }

    // ✅ Ensure storage permission
    if (!(await Permission.manageExternalStorage.isGranted)) {
      await Permission.manageExternalStorage.request();
    }
    // Create Excel file
    DateFormat formatter = DateFormat('dd-MM-yyyy');
    String startDateStr = formatter.format(startDate!);
    String endDateStr = formatter.format(endDate!);

    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    sheet.appendRow([
      'Date',
      'Inv No',
      'Party Name',
      'Product Name',
      'Qty',
      'Rate',
      'Amount',
      'Party Type',
      'Type',
      'Place Of Supply',
      'Registration Type',
    ]);

    for (var entry in salesEntries) {
      sheet.appendRow([
        entry['Date'],
        entry['Invoice No'],
        entry['Party'],
        entry['Product'],
        entry['Quantity'],
        entry['Rate'],
        entry['Amount'],
        'Sundry Debtors',
        'Debit',
        'MAHARASHTRA',
        'Consumer',
      ]);
    }
    // Encode Excel file
    var fileBytes = excel.encode();
    if (fileBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate Excel file')));
      return;
    }

    // Save file in selected location
    String filePath =
        "$selectedDirectory/sales_${startDateStr}_to_${endDateStr}.xlsx";
    File file = File(filePath);
    try {
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported successfully to $filePath')),
      );
      print("File saved at: $filePath");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Export Sales Data')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(
                startDate == null || endDate == null
                    ? 'Select Date Range'
                    : 'Selected: ${DateFormat('dd-MM-yyyy').format(startDate!)} to ${DateFormat('dd-MM-yyyy').format(endDate!)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: _selectDateRange,
            ),
            SizedBox(height: 10),

            // Product Summary
            if (productSummary.isNotEmpty) ...[
              Text(
                'Product Summary :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Card(
                color:
                    Colors.grey[100], // Light background for better readability
                elevation: 2, // Slight shadow for a lifted effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        productSummary.entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ] else ...[
              Text(
                'No data found for the selected date range.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
            ],
            ElevatedButton(
              onPressed: _exportToExcel,
              child: Text('Export to Excel'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
