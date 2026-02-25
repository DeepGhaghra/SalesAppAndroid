import 'package:get/get.dart';
import 'package:sales_app/app/modules/sales_entries/controllers/sales_list_controller.dart';
import '../repository/sales_entries_repository.dart';

import '../controllers/sales_entries_controller.dart';

class SalesEntriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesEntriesRepository>(() => SalesEntriesRepository());

    Get.lazyPut<SalesEntriesController>(() => SalesEntriesController());
  }
}
class SalesListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesListController>(() => SalesListController());
  }
}