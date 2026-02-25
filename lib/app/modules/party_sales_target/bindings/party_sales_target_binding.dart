import 'package:get/get.dart';

import '../controllers/party_sales_target_controller.dart';

class PartySalesTargetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PartySalesTargetController>(
      () => PartySalesTargetController(),
    );
  }
}
