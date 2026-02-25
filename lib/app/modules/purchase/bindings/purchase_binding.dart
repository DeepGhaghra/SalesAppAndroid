import 'package:get/get.dart';
import '../controllers/purchase_controller.dart';
import '../repository/purchase_repository.dart';

class PurchaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseRepository>(() => PurchaseRepository());
    Get.lazyPut<PurchaseController>(
      () => PurchaseController(
        purchaseRepository: Get.find<PurchaseRepository>(),
      ),
    );
  }
}
