import 'package:get/get.dart';
import '../repository/sales_entries_repository.dart';

import '../controllers/sales_entries_controller.dart';

class SalesEntriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesEntriesRepository>(() => SalesEntriesRepository());

    Get.lazyPut<SalesEntriesController>(() => SalesEntriesController());
  }
}
