import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/modules/stock_view/repository/stock_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/PartyInfo.dart';
import '../../stock_view/model/StockList.dart';
import '../repository/sales_entries_repository.dart';
import 'dart:html' as html;

class SalesEntriesController extends GetxController {
  final supabase = Supabase.instance.client;

  Rx<DateTime> selectedDate = DateTime.now().obs;
  RxString invoiceNo = ''.obs;
  RxnString selectedParty = RxnString();
  RxnString selectedPartyName = RxnString();
  RxList<String> selectedProducts = <String>[].obs;

  final formKey = GlobalKey<FormState>();
  final qtyControllers = <String, TextEditingController>{};
  final rateControllers = <String, TextEditingController>{};
  final rates = <String, int>{}.obs;
  final amounts = <String, int>{}.obs;
  final rateFieldColor = <String, Color>{}.obs;

  final SalesEntriesRepository _salesEntriesRepository =
      SalesEntriesRepository();

  final StockRepository _stockRepository = StockRepository();
  // RxList<String> partyList = <String>[].obs;

  RxList<PartyInfo> partyList = RxList();
  RxList<StockList> designList = RxList();

  RxList<String> productList = <String>[].obs;

  final partyMap = <String, String>{};
  final productMap = <String, String>{};
  final priceList = <String, Map<String, int>>{};
  final productRates = <String, int>{};
  final designMap = <String, String>{};
  RxBool isLoading = true.obs;

  RxList<Map<String, dynamic>> salesEntries = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    generateInvoiceNo();
    loadData();
    fetchRecentSales();
  }

  // Fetch parties and sort by partyName
  Future<void> fetchParties() async {
    try {
      final partyResponse = await _salesEntriesRepository.fetchParties();

      // Update partyList with fetched data and sort
      partyList.value = partyResponse;
      partyList.sort((a, b) => a.partyName.compareTo(b.partyName));
    } catch (e) {
      print('Error in PartyController while fetching parties: $e');
    }
  }

  Future<int> getTotalCount() async {
    try {
      return await _salesEntriesRepository.getTotalCount();
    } catch (e) {
      print('Error in PartyController while getting total count: $e');
      rethrow;
    }
  }

  // Fetch parties and sort by partyName
  Future<void> fetchStocks() async {
    try {
      final designResponse = await _stockRepository.fetchStockList();
      if (designResponse.isEmpty) {
        print("WARNING: Design list is empty!");
      } else {
        print("First design: ${designResponse.first.designNo}");
      }

      // Update designlist with fetched data and sort
      designList.value = designResponse;
      designList.sort((a, b) => a.designNo.compareTo(b.designNo));
    } catch (e) {
      print('Error in stockController while fetching stocks: $e');
    }
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      //final partyResponse = await supabase.from('parties').select();
      final productResponse = await supabase.from('product_head').select();
      final priceResponse = await supabase.from('pricelist').select();
      //final designResponse = await supabase.from('products_design').select();

      await fetchParties();
      await fetchStocks();
      await getTotalCount();

      // partyList.value = partyResponse.map<String>((p) {
      //   final name = p['partyname'].toString();
      //   partyMap[name] = p['id'].toString();
      //   return name;
      // }).toList();
      // partyList.sort();

      productList.value =
          productResponse.map<String>((p) {
            productMap[p['product_name']] = p['id'].toString();
            return p['product_name'].toString();
          }).toList();
      productList.sort();

      for (var product in productResponse) {
        productRates[product['product_name']] = product['product_rate'];
      }

      for (var price in priceResponse) {
        final partyId = price['party_id'].toString();
        final productId = price['product_id'].toString();
        final rate = price['price'];

        priceList[partyId] ??= {};
        priceList[partyId]![productId] = rate;
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateInvoiceNo() async {
    invoiceNo.value = await _salesEntriesRepository.generateInvoiceNo();
  }

  void updateRate(String product) {
    String? productId = productMap[product];
    int? partySpecificRate = priceList[selectedParty?.value]?[productId];
    int? baseRate = productRates[product];

    if (partySpecificRate != null) {
      rates[product] = partySpecificRate;
      rateControllers[product]?.text = partySpecificRate.toString();

      rateFieldColor[product] = Colors.white;
    } else if (baseRate != null) {
      rates[product] = baseRate;
      rateControllers[product]?.text = baseRate.toString();
      rateFieldColor[product] = const Color.fromARGB(255, 220, 237, 246);
    } else {
      rates[product] = 0;
    }
    calculateAmount(product);
  }

  void calculateAmount(String product) {
    int qty = int.tryParse(qtyControllers[product]?.text ?? '0') ?? 0;
    int rate = int.tryParse(rateControllers[product]?.text ?? '0') ?? 0;
    amounts[product] = qty * rate;
  }

  void onProductSelected(List<String> designNumbers) {
    selectedProducts.value = designNumbers;
    for (var designNo in designNumbers) {
      qtyControllers[designNo] ??= TextEditingController();
      rateControllers[designNo] ??= TextEditingController();
      updateRate(designNo);
    }
  }

  void printSalesEntry(
    String invoiceNo,
    String? partyName,
    List<Map<String, dynamic>> products,
  ) {
    // Create HTML content with the format similar to the image
    StringBuffer htmlContent = StringBuffer();

    // Basic HTML structure with styling
    htmlContent.writeln('''
    <html>
    <head>
      <title>Sales Challan</title>
      <style>
      @page {
        size: 105mm 148mm;
        margin: 0;
      }
        html,body {
            font-family: "Times New Roman", Times, serif;
            margin: 0;
            padding: 0;
            width: 105mm;
            height: 148mm;
            overflow: hidden;
        }
        .page {
            width: 100%;
            height: 100%;
            padding: 8mm;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
          }
        .challan {
            width: 100%;
            padding: 10px;
            border: 1px solid black;
            box-sizing: border-box;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .header {
            font-size: 14px;
            line-height: 1.4;
            font-weight: bold;
            text-align: center;
        }

       .party-section {
          font-size: 12px;
          margin-top: 10px;
          margin-bottom: 10px;
        }

        .party-name {
          font-weight: bold;
          word-wrap: break-word;
          white-space: normal;
        }

        .row-between {
          display: flex;
          justify-content: space-between; /* Date to left, Mobile to right */
          align-items: center;
          margin-top: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 10px;
            flex-grow: 1;
            table-layout: fixed;
        }

        th,
        td {
            border: 1px solid black;
            padding: 5px;
            text-align: center;
            word-wrap: break-word;
        }

        .total-row td {
            font-weight: bold;
        }

        .filler td {
            height: 100%;
        }

        @media print {
            body,
            html {
                height: 100%;
            }
        }
      </style>
    </head>
    <body>
  ''');

    // Header section
    htmlContent.writeln('''
  <div class="page">
    <div class="challan">
      <div class="header">           
            ESTIMATE - SH<br>
        </div>
  ''');

    // Party information
    htmlContent.writeln('''
    <div class="party-section">
      <div class="party-name"><strong>M/s:</strong> ${partyName ?? 'N/A'}</div>
    <div class="row-between">
            <div><strong>Mobile:</strong> 9876543210</div>
            <div><strong>Date:</strong> ${DateFormat('dd-MM-yyyy').format(selectedDate.value)}</div>
        </div>
      </div>
  ''');

    // Products table
    htmlContent.writeln('''
    <table>
      <tr>
          <th style="width: 8%;">Sr.</th>
          <th style="width: 22%;">Brand</th>
          <th style="width: 18%;">Location</th>
          <th style="width: 28%;">Design No.</th>
          <th style="width: 10%;">Qty</th>
          <th style="width: 14%;border: 1px solid black;"></th>
      </tr>
  ''');
    // Add products to the table
    int totalQty = 0;
    for (int i = 0; i < products.length; i++) {
      var product = products[i];

      // Parse the product name to extract components (assuming format from your MultiSelectSearchDropdown)
      String productName = product['product_name'];
      List<String> parts = productName.split(' || ');
      String designNo = parts.isNotEmpty ? parts[0] : productName;
      String location = parts.length > 1 ? parts[1] : 'N/A';
      String brand = 'N/A';
      for (var design in designList) {
        if (design.designNo == designNo) {
          brand = design.folderName;
          break;
        }
      }

      int qty = int.tryParse(product['quantity'] ?? '0') ?? 0;
      totalQty += qty;

      htmlContent.writeln('''
      <tr>
        <td>${i + 1}</td>
        <td>$brand</td>
        <td>$location</td>
        <td>$designNo</td>
        <td>$qty</td>
        <td></td>
      </tr>
     
    ''');
    }

    // Close table and add total
    htmlContent.writeln(''' <tr class="filler">
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
        </tr>
<tr class="total-row">
                    <td colspan="4" style="text-align: right;font-size:12px;">Total</td>
                    <td> $totalQty</td>
                    <td></td>
                </tr>
                <tr>
                    <td colspan="5" style="text-align: left; padding-top: 10px;">Delivery By:</td>
                    <td></td>
                </tr>
          
        </table> ''');
    /* </table>
    <div class="total">Total $totalQty</div>*/

    // Footer section
    /*htmlContent.writeln('''
    <div class="footer">
      <div>Receiver's Signature</div>
      <div>Authorized Signature</div>
    </div>
  ''');*/ /*<div style="margin-top: 20px; text-align: center;">
    <button onclick="window.print()" style="padding: 8px 16px; margin-right: 10px;"> Print</button>
    <button onclick="window.close()" style="padding: 8px 16px;"> Close Window</button>
  </div>*/
    htmlContent.writeln(('''
 
  
  <script>
    window.onload = function() {
      window.print();
    }
  </script>'''));
    // Close HTML
    htmlContent.writeln('</body></html>');

    // Create a Blob and trigger the print dialog
    final blob = html.Blob([htmlContent.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute('target', '_blank')
          ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> fetchRecentSales() async {
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

      if (response != null) {
        salesEntries.value =
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
      }
    } catch (e) {
      debugPrint('Error fetching recent sales: $e');
    }
  }
}
