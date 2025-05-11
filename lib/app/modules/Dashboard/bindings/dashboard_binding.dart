import 'package:get/get.dart';


import '../../../core/utils/globle_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
    );

    Get.lazyPut<GlobalController>(
          () => GlobalController(),
    );
  }
}
