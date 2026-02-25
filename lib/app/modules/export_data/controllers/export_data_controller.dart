import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExportDataController extends GetxController {
  Rxn<DateTime> startDate = Rxn<DateTime>();
  Rxn<DateTime> endDate = Rxn<DateTime>();
  RxList<Map<String, dynamic>> salesEntries = <Map<String, dynamic>>[].obs;
  RxMap<String, int> productSummary = <String, int>{}.obs;

  final supabase = Supabase.instance.client;

  Future<void> fetchSalesData(BuildContext context) async {
    if (startDate.value == null || endDate.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }

    try {
      final response = await supabase
          .from('sales_entries')
          .select(
        'date, invoiceno, quantity, rate, amount, parties (partyname), product_head (product_name)',
      )
          .gte('date', DateFormat('dd-MM-yyyy').format(startDate.value!))
          .lte('date', DateFormat('dd-MM-yyyy').format(endDate.value!))
          .order('date', ascending: true);

      Map<String, int> tempProductSummary = {};
      salesEntries.value = response.map<Map<String, dynamic>>((entry) {
        String productName = entry['product_head']['product_name'];
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

      productSummary.value = tempProductSummary;
    } catch (e) {
      print('Error fetching sales data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch data from Supabase')),
      );
    }
  }

  Future<void> selectDateRange(BuildContext context) async {
    DateTime today = DateTime.now();

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: today,
      initialDateRange: startDate.value != null && endDate.value != null
          ? DateTimeRange(start: startDate.value!, end: endDate.value!)
          : DateTimeRange(start: today, end: today),
    );

    if (picked != null) {
      startDate.value = picked.start;
      endDate.value = picked.end;
      fetchSalesData(context);
    }
  }

  Future<void> exportToExcel(BuildContext context) async {
    if (startDate.value == null || endDate.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }
    if (salesEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sales data available for export')),
      );
      return;
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export cancelled or permission denied')),
      );
      return;
    }

    if (!(await Permission.manageExternalStorage.isGranted)) {
      await Permission.manageExternalStorage.request();
    }

    DateFormat formatter = DateFormat('dd-MM-yyyy');
    String startDateStr = formatter.format(startDate.value!);
    String endDateStr = formatter.format(endDate.value!);

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

    var fileBytes = excel.encode();
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel file')),
      );
      return;
    }

    String filePath =
        "$selectedDirectory/sales_${startDateStr}_to_${endDateStr}.xlsx";
    File file = File(filePath);
    try {
      await file.writeAsBytes(fileBytes);
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
}
