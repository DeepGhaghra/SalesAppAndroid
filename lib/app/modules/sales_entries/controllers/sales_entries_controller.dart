import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  RxList<String> partyList = <String>[].obs;
  RxList<String> productList = <String>[].obs;
  final partyMap = <String, String>{};
  final productMap = <String, String>{};
  final priceList = <String, Map<String, int>>{};
  final productRates = <String, int>{};

  RxBool isLoading = true.obs;

  RxList<Map<String, dynamic>> salesEntries = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    generateInvoiceNo();
    loadData();
    fetchRecentSales();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final partyResponse = await supabase.from('parties').select();
      final productResponse = await supabase.from('product_head').select();
      final priceResponse = await supabase.from('pricelist').select();

      partyList.value = partyResponse.map<String>((p) {
        final name = p['partyname'].toString();
        partyMap[name] = p['id'].toString();
        return name;
      }).toList();
      partyList.sort();

      productList.value = productResponse.map<String>((p) {
        productMap[p['product_name']] = p['id'].toString();
        return p['product_name'].toString();
      }).toList();

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

  void generateInvoiceNo() {
    invoiceNo.value = '1000${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  void updateRate(String product) {
    String? productId = productMap[product];
    int? partySpecificRate = priceList[selectedParty?.value]?[productId];
    int? baseRate = productRates[product];

    if (partySpecificRate != null) {
      rates[product] = partySpecificRate;
      rateFieldColor[product] = Colors.white;
    } else if (baseRate != null) {
      rates[product] = baseRate;
      rateControllers[product]?.text = baseRate.toString();
      rateFieldColor[product] = const Color.fromARGB(255, 220, 237, 246);
    } else {
      rates[product] = 0;
    }

    rateControllers[product]?.text = rates[product]!.toString();
    calculateAmount(product);
  }

  void calculateAmount(String product) {
    int qty = int.tryParse(qtyControllers[product]?.text ?? '0') ?? 0;
    int rate = int.tryParse(rateControllers[product]?.text ?? '0') ?? 0;
    amounts[product] = qty * rate;
  }

  void onProductSelected(List<String> products) {
    selectedProducts.value = products;
    for (var product in products) {
      qtyControllers[product] ??= TextEditingController();
      rateControllers[product] ??= TextEditingController();
      updateRate(product);
    }
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
        salesEntries.value = response.map<Map<String, dynamic>>((entry) {
          return {
            'id': entry['id'].toString(),
            'date': entry['date'].toString(),
            'invoiceno': entry['invoiceno'].toString(),
            'party_name': entry['parties']['partyname'].toString(),
            'product_name': entry['product_head']['product_name'].toString(),
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
