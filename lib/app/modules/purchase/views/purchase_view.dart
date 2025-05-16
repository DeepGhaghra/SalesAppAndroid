import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/core/utils/app_colors.dart';
import 'package:sales_app/app/modules/purchase/controllers/purchase_controller.dart';

class PurchaseViewScreen extends GetView<PurchaseController> {
  PurchaseViewScreen({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Purchase")),
      body: Obx(
        () => Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  Row(
                    children: [
                      Text(
                        "Date: ${DateFormat('dd-MM-yyyy').format(controller.selectedDate.value)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlackDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_today,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: controller.selectedDate.value,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            controller.selectedDate.value = picked;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Party Dropdown
                  SearchableDropdown(
                    key: UniqueKey(),
                    labelText: "Select Party",
                    hintText: "Select Party",
                    selectedItem: controller.selectedPartyItem,
                    items:
                        controller.partyList
                            .map(
                              (p) =>
                                  Item(id: p.id.toString(), name: p.partyName),
                            )
                            .toList(),

                    onItemSelected: (Item selectedItem) {
                      controller.selectedPartyName.value = selectedItem.name;
                      controller.selectedParty.value = selectedItem.id;
                      controller.selectedPartyItem = selectedItem;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Design Dropdown
                  SearchableDropdown(
                    key: UniqueKey(),
                    labelText: 'Select Design',
                    hintText: 'Select Design',
                    selectedItem: controller.selectedDesignItem,
                    items:
                        controller.designList
                            .map(
                              (d) => Item(
                                id: d.designId.toString(),
                                name: d.designNo ?? 'Unknown Design',
                              ),
                            )
                            .toList(),

                    onItemSelected: (Item selected) {
                      controller.selectedDesignName.value = selected.name;
                      controller.designId.value =
                          int.tryParse(selected.id) ?? 0;

                      controller.selectedDesignItem = selected;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Location Dropdown
                  SearchableDropdown(
                    key: UniqueKey(),
                    labelText: 'Select Location',
                    hintText: 'Select Location',
                    selectedItem: controller.selectedLocationItem,
                    items:
                        controller.locationList
                            .map(
                              (d) => Item(
                                id: d.locationId.toString(),
                                name: d.locationName!,
                              ),
                            )
                            .toList(),

                    onItemSelected: (Item selected) {
                      controller.selectedLocationName.value = selected.name;
                      controller.locationId.value =
                          int.tryParse(selected.id) ?? 0;
                      controller.selectedLocationItem = selected;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Quantity Input
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    controller: controller.qtyController,

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Please enter valid quantity';
                      }
                      return null;
                    },
                    onChanged:
                        (val) => controller.qty.value = int.tryParse(val) ?? 0,
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          controller.addPurchaseWithFunction();
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
