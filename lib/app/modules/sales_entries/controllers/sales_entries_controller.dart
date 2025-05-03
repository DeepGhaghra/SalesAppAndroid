import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/modules/stock_view/repository/stock_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/PartyInfo.dart';
import '../../stock_view/model/StockList.dart';
import '../repository/sales_entries_repository.dart';

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

  void generateInvoiceNo() {
    invoiceNo.value = '1000${DateTime.now().millisecondsSinceEpoch % 1000}';
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
