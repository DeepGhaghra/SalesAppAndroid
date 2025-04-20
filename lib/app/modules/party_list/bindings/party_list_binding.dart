import 'package:get/get.dart';

import '../controllers/party_list_controller.dart';

class PartyListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PartyListController>(
      () => PartyListController(),
    );
  }
}
