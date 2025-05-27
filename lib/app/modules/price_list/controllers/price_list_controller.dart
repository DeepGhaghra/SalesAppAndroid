import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/modules/price_list/model/PriceList.dart';
import 'package:sales_app/app/modules/price_list/repository/price_list_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PriceListController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final PriceListRepository repository = PriceListRepository();

  var fullProductList = <Map<String, dynamic>>[].obs;
  var partyPrices = <int, dynamic>{}.obs;
  var partySuggestions = <String>[].obs;
  var selectedPartyId = RxnString();
  var isFetchingPrices = false.obs;
  var isUserTyping = false.obs;

  final partyController = TextEditingController();
  final partyFocusNode = FocusNode();
  RxList<Item> partyDropdownItems = <Item>[].obs;
  Rxn<Item> selectedParty = Rxn<Item>();
  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchParties('');
    partyFocusNode.addListener(() {
      if (!partyFocusNode.hasFocus) {
        partySuggestions.clear();
      }
    });
  }

  Future<void> fetchParties(String query) async {
    final parties = await repository.searchParties(query);
    partyDropdownItems.value = parties.map((p) => p.toDropdownItem()).toList();
  }

  void onPartySelected(Item partyItem) {
    selectedParty.value = partyItem;
    fetchPartyPrices(partyItem.id);
  }

  Future<void> fetchProducts() async {
    try {
      final response = await repository.fetchProducts();
      fullProductList.value =
          response.map((item) {
            return {
              'id': item['id'],
              'product_name': item['product_name'] ?? 'Unknown',
              'product_rate': item['product_rate'] ?? 0,
            };
          }).toList();

      fullProductList.sort((a, b) {
        final nameA = (a['product_name'] ?? '') as String;
        final nameB = (b['product_name'] ?? '') as String;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });
    } catch (e) {
      print("❌ Error fetching products: $e");
    }
  }

  Future<void> fetchPartyPrices(String partyId) async {
    if (isFetchingPrices.value) return;

    isFetchingPrices.value = true;
    isUserTyping.value = false;

    try {
      final response = await supabase
          .from('pricelist')
          .select('product_id, price')
          .eq('party_id', partyId);

      partyPrices.value = {
        for (var item in response) item['product_id']: item['price'],
      };
      partySuggestions.clear();
    } catch (e) {
      print("❌ Error fetching price list: $e");
    } finally {
      isFetchingPrices.value = false;
    }
  }

  Future<void> updatePrice(
    int productId,
    String newPrice,
    BuildContext context,
  ) async {
    if (newPrice.isEmpty || int.tryParse(newPrice) == null) {
      Fluttertoast.showToast(msg: "⚠️ Enter a valid price!");
      return;
    }

    final partyIdInt = int.tryParse(selectedPartyId.value ?? '');
    if (partyIdInt == null) {
      Fluttertoast.showToast(msg: "⚠️ Select party First then Edit rates!");
      return;
    }

    final priceInt = int.parse(newPrice);
    try {
      if (partyPrices.containsKey(productId)) {
        await supabase.from('pricelist').update({'price': priceInt}).match({
          'party_id': partyIdInt,
          'product_id': productId,
        });
      } else {
        await supabase.from('pricelist').insert({
          'party_id': partyIdInt,
          'product_id': productId,
          'price': priceInt,
        });
      }

      Fluttertoast.showToast(msg: "✅ Price updated!");
      Navigator.pop(context);
      fetchPartyPrices(partyController.text);
    } catch (e) {
      print("❌ Error updating price: $e");
    }
  }
}
