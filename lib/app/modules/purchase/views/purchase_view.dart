import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales_app/app/core/common/base_screen.dart';
import 'package:sales_app/app/core/common/search_drop_down.dart';
import 'package:sales_app/app/core/utils/app_colors.dart';
import 'package:sales_app/app/modules/purchase/controllers/purchase_controller.dart';

class PurchaseViewScreen extends GetView<PurchaseController> {
  PurchaseViewScreen({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      nameOfScreen: "Purchase",

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

                  const SizedBox(height: 10),
                  // Bulk Purchase Items List
                  const Text(
                    "Purchase Items:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  Obx(
                    () => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.bulkPurchaseItems.length,
                      itemBuilder: (context, index) {
                        return _buildPurchaseItemRow(context, index);
                      },
                    ),
                  ),

                  // Add Row Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.green,
                        size: 32,
                      ),
                      onPressed: () {
                        controller.addNewRow();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          controller.saveBulkPurchase();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          controller.isLoading.value
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('Save All Purchases'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      globalKey: GlobalKey(),
    );
  }

  Widget _buildPurchaseItemRow(BuildContext context, int index) {
    final item = controller.bulkPurchaseItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: SearchableDropdown(
                    key: ValueKey('design_$index'),
                    labelText: 'Design ${index + 1}',
                    hintText: 'Select Design',
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
                      item.designId = int.tryParse(selected.id) ?? 0;
                      item.designName = selected.name;
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: SearchableDropdown(
                    key: ValueKey('location_$index'),
                    labelText: 'Location',
                    hintText: 'Select Location',
                    items:
                        controller.locationList
                            .map(
                              (l) => Item(
                                id: l.locationId.toString(),
                                name: l.locationName ?? 'Unknown Location',
                              ),
                            )
                            .toList(),
                    onItemSelected: (Item selected) {
                      item.locationId = int.tryParse(selected.id) ?? 0;
                      item.locationName = selected.name;
                    },
                  ),
                ),
                const SizedBox(width: 4),

                Expanded(
                  flex: 1,
                  child: TextFormField(
                    key: ValueKey('qty_$index'),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    controller: item.quantityController,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Enter valid quantity';
                      }
                      if ((int.tryParse(value) ?? 0) <= 0) {
                        return 'Quantity must be > 0';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      item.quantity = int.tryParse(val);
                    },
                  ),
                ),
                if (controller.bulkPurchaseItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => controller.removeRow(index),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
