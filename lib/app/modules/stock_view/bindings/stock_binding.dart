import 'package:get/get.dart';
import 'package:sales_app/app/modules/stock_view/controllers/stock_controller.dart';
import 'package:sales_app/app/modules/stock_view/controllers/stocktransfer_controller.dart';
import 'package:sales_app/app/modules/stock_view/controllers/addnewstock_controller.dart';
import 'package:sales_app/app/modules/stock_view/controllers/location_controller.dart';

class StockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockController>(() => StockController());
  }
}

class StockTransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockTransferController>(() => StockTransferController());
  }
}

class AddnewStockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddStockController>(() => AddStockController());
  }
}

class LocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationController>(() => LocationController());
  }
}
