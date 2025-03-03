import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportDataScreen extends StatefulWidget {
    const ExportDataScreen({super.key});

  @override
  _ExportDataScreenState createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> salesEntries = [];

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? salesDataString = prefs.getString('sales_entries');

    if (salesDataString != null) {
      List<String> dataList = salesDataString.split('|');
      List<Map<String, dynamic>> tempEntries = [];

      for (String data in dataList) {
        List<String> values = data.split(',');
        tempEntries.add({
          'Date': values[0],
          'Invoice No': int.parse(values[1]),
          'Party': values[2],
          'Product': values[3],
          'Quantity': int.parse(values[4]),
        });
      }

      setState(() {
        salesEntries = tempEntries;
      });
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
    }
  }

  Future<void> _exportToExcel() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }

    // Ask user where to save the file
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export canceled or permission denied')),
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
    sheet.appendRow(['Date', 'Inv No', 'Party Name', 'Product Name', 'Qty','Rate','Amount',
    'Party Type','Type','Place Of Supply','Party Type']);

    for (var entry in salesEntries) {
      DateTime entryDate = DateTime.parse(entry['Date']);
      if (entryDate.isAtSameMomentAs(startDate!) ||
          (entryDate.isAfter(startDate!) && entryDate.isBefore(endDate!)) ||
          entryDate.isAtSameMomentAs(endDate!)) {
        sheet.appendRow([
          entry['Date'],
          entry['Invoice No'],
          entry['Party'],
          entry['Product'],
          (int.tryParse(entry['qty']) ?? 0),
          (int.tryParse(entry['rate'].toString()) ?? 0),
          (int.tryParse(entry['amount'].toString()) ?? 0),
          'Sundry Debtors',
          'Debit',
          'MAHARASHTRA',
          'Consumer'
        ]);
      }
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
          "$selectedDirectory/sales_data_${startDateStr}_to_${endDateStr}.xlsx";
      File file = File(filePath);
      try {    await file.writeAsBytes(excel.encode()!);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported successfully to $filePath')),
      );
          print("File saved at: $filePath");

    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving file: $e')),
    );
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
                    : 'From ${DateFormat('dd-MM-yyyy').format(startDate!)} to ${DateFormat('dd-MM-yyyy').format(endDate!)}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: _selectDateRange,
            ),
            SizedBox(height: 10),
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
