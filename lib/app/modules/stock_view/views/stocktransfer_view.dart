import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';
import 'package:sales_app/app/routes/app_pages.dart';
import '../controllers/stocktransfer_controller.dart';

class StockTransferScreen extends StatelessWidget {
  final controller = Get.put(StockTransferController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Transfer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.toNamed(Routes.STOCKVIEW),
        ),
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SearchableDropdown(
                key: ValueKey(
                  controller.selectedDesign.value?.id ?? 'no_design_none',
                ),

                items:
                    controller.designList
                        .map(
                          (design) => Item(
                            id: design.id.toString(),
                            name: design.designNo,
                            isSelected:
                                controller.selectedDesign.value?.id ==
                                design.id,
                          ),
                        )
                        .toList(),
                selectedItem:
                    controller.selectedDesign.value != null
                        ? Item(
                          id: controller.selectedDesign.value!.id.toString(),
                          name: controller.selectedDesign.value!.designNo,
                        )
                        : null,
                onItemSelected: (item) async {
                  final selected = controller.designList.firstWhere(
                    (d) => d.id.toString() == item.id,
                  );
                  await controller.onDesignChanged(selected);
                },
                hintText: "Select Design",
                labelText: "Design Number",
              ),
              const SizedBox(height: 16),
              // Disable the dropdown if no design is selected
              // Update the From Location Dropdown section to this:
              Obx(() {
                if (controller.selectedDesign.value == null) {
                  return AbsorbPointer(
                    absorbing: true,
                    child: Opacity(
                      opacity: 0.5,
                      child: SearchableDropdown(
                        items: [],
                        selectedItem: null,
                        onItemSelected: (_) {},
                        hintText: "Please select a design first",
                        labelText: "From Location",
                      ),
                    ),
                  );
                }

                // Show loading indicator while locations are being fetched
                if (controller.isLoading.value) {
                  return const CircularProgressIndicator();
                }

                return SearchableDropdown(
                  key: ValueKey(
                    'from_location_${controller.selectedDesign.value?.id}',
                  ),

                  items:
                      controller.availableFromLocations.map((loc) {
                        final qty =
                            controller.designLocationQuantities[loc.id] ?? 0;
                        return Item(
                          id: loc.id.toString(),
                          name: '${loc.name} (Available: $qty)',
                          isSelected:
                              controller.selectedFromLocation.value?.id ==
                              loc.id,
                        );
                      }).toList(),
                  selectedItem:
                      controller.selectedFromLocation.value != null
                          ? Item(
                            id:
                                controller.selectedFromLocation.value!.id
                                    .toString(),
                            name:
                                '${controller.selectedFromLocation.value!.name} '
                                '(Available: ${controller.designLocationQuantities[controller.selectedFromLocation.value!.id] ?? 0})',
                          )
                          : null,
                  onItemSelected: (item) {
                    controller.selectedFromLocation.value = controller
                        .availableFromLocations
                        .firstWhere((l) => l.id.toString() == item.id);
                  },
                  hintText:
                      controller.availableFromLocations.isEmpty
                          ? "No available locations for this design"
                          : "Select Location",
                  labelText: "From Location",
                );
              }),
              const SizedBox(height: 16),
              // To Location Dropdown (disabled until design is selected)
              AbsorbPointer(
                absorbing: controller.selectedDesign.value == null,
                child: Opacity(
                  opacity: controller.selectedDesign.value == null ? 0.5 : 1.0,
                  child: SearchableDropdown(
                    items:
                        controller.allLocations
                            .map(
                              (loc) => Item(
                                id: loc.id.toString(),
                                name: loc.name,
                                isSelected:
                                    controller.selectedToLocation.value?.id ==
                                    loc.id,
                              ),
                            )
                            .toList(),
                    selectedItem:
                        controller.selectedToLocation.value != null
                            ? Item(
                              id:
                                  controller.selectedToLocation.value!.id
                                      .toString(),
                              name: controller.selectedToLocation.value!.name,
                            )
                            : null,
                    onItemSelected: (item) {
                      controller.selectedToLocation.value = controller
                          .allLocations
                          .firstWhere((l) => l.id.toString() == item.id);
                    },
                    hintText:
                        controller.selectedDesign.value == null
                            ? "Please select a design first"
                            : "Select Location",
                    labelText: "To Location",
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                ),
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
                        onPressed: () => Get.toNamed(Routes.STOCKVIEW),
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
