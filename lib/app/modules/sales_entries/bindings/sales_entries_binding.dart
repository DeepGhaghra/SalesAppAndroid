import 'package:get/get.dart';

import '../controllers/sales_entries_controller.dart';

class SalesEntriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesEntriesController>(
      () => SalesEntriesController(),
    );
  }
}
