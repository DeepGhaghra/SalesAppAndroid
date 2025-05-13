
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';


import '../../data/service/shop.dart';

class GlobalController extends GetxController {

  var shopList = <Shop>[].obs;
  var selectedShopId = RxnString("1");


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    shopList.add(Shop(id: "1", name: "first shop"));
    shopList.add(Shop(id: "2", name: "second shop"));

  }

  void selectShop(String shopId) {
    selectedShopId.value = shopId;
  }

  Shop? get selectedShop =>
      shopList.firstWhereOrNull((shop) => shop.id == selectedShopId.value);

}
