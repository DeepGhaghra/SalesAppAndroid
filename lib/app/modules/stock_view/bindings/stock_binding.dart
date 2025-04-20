import 'package:get/get.dart';
import 'package:sales_app/app/modules/stock_view/controllers/stock_controller.dart';



class StockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockController>(
      () => StockController(),
    );
  }
}
