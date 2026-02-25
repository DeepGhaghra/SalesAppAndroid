import 'package:get/get.dart';

import '../controllers/price_list_controller.dart';

class PriceListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PriceListController>(
      () => PriceListController(),
    );
  }
}
