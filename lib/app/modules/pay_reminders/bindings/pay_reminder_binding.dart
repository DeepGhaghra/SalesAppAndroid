


import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';

import '../controllers/pay_reminder_controller.dart';

class PayReminderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PayReminderController>(
          () => PayReminderController(),
    );
  }
}
