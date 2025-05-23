import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/modules/stock_view/repository/stock_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationController extends GetxController {
  final StockRepository repository = StockRepository();

  RxList<Map<String, dynamic>> locations = <Map<String, dynamic>>[].obs;
  final TextEditingController nameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    final fetched = await repository.fetchLocations();
    fetched.sort(
      (a, b) => a['name'].toLowerCase().compareTo(b['name'].toLowerCase()),
    );
    locations.value = fetched;
  }

  Future<void> addLocation(String name) async {
    try {
      await repository.addLocation(name);
      await fetchLocations();
      SnackbarUtil.showSuccess("Location Added Successfully");
    } catch (e) {
      SnackbarUtil.showError("Error,Location not Added");
    }
  }

  Future<void> editLocation(int id, String newName) async {
    try {
      await repository.updateLocation(id, newName);
      await fetchLocations();
      SnackbarUtil.showSuccess(
        "Location updated and all associated stocks adjusted.",
      );
    } catch (e) {
      SnackbarUtil.showError("Error, Location not updated ");
    }
  }
}
