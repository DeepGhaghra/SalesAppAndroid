import 'package:get/get.dart';

import '../controllers/export_data_controller.dart';

class ExportDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExportDataController>(
      () => ExportDataController(),
    );
  }
}
