import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stocktransfer_controller.dart';
class StockTransferScreen extends StatelessWidget {
  final StockTransferController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Transfer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Design Number"),
                onChanged: (value) => controller.designNumber.value = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: controller.fromLocation.value.isEmpty
                    ? null
                    : controller.fromLocation.value,
                items: controller.locations
                    .map((loc) =>
                        DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (val) => controller.fromLocation.value = val ?? '',
                decoration: const InputDecoration(labelText: "From Location"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: controller.toLocation.value.isEmpty
                    ? null
                    : controller.toLocation.value,
                items: controller.locations
                    .map((loc) =>
                        DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (val) => controller.toLocation.value = val ?? '',
                decoration: const InputDecoration(labelText: "To Location"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                onChanged: (val) => controller.quantity.value = val,
              ),
              const SizedBox(height: 24),
              controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: controller.transferStock,
                          child: const Text("Transfer Stock"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text("Back to Stock View"),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
