import 'package:drop_down_list/drop_down_list.dart';
import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:sales_app/app/core/common/base_screen.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';

import '../../../core/common/app_drawer.dart';
import '../../../core/common/multi_select_drop_down.dart';
import '../../../core/common/search_drop_down.dart';
import '../../../core/utils/app_colors.dart';
import '../controllers/sales_entries_controller.dart';

class SalesEntriesView extends GetView<SalesEntriesController> {
  const SalesEntriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      nameOfScreen: "Sales Entry",
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Date Selector
                _buildDateSelector(context),
                const SizedBox(height: 10),

                SearchableDropdown(
                  key: UniqueKey(),
                  labelText: "Select Party",
                  hintText: "Select Party",
                  selectedItem: controller.selectedPartyItem,

                  items:
                      controller.partyList.map((element) {
                        return Item(
                          id: element.id,
                          name: element.partyName,
                          isSelected: element.isSelected,
                        );
                      }).toList(),

                  onItemSelected: (Item selectedItem) {
                    controller.selectedPartyName.value = selectedItem.name;
                    controller.selectedParty.value = selectedItem.id;
                    controller.selectedPartyItem = selectedItem;
                  },
                ),

                const SizedBox(height: 20),
                MultiSelectSearchDropdown(
                  labelText: "Select Designs",
                  items:
                      controller.designList.map((element) {
                        return MultiSelectItemModel(
                          id: element.id,
                          name:
                              "${element.designNo} (${element.location}) [${element.qtyAtLocation}]",
                        );
                      }).toList(),

                  selectedItems:
                      controller.selectedProducts.map((id) {
                        final design = controller.designList.firstWhere(
                          (d) => d.id == id,
                          orElse:
                              () => StockList(
                                designNo: '',
                                folderName: '',
                                id: '0',
                                designId: '0',
                                location: '',
                                qtyAtLocation: '0',
                                locationid: '0',
                                productId: '0',
                                rate: 0,
                              ),
                        );
                        return MultiSelectItemModel(
                          id: id,
                          name:
                              "${design.designNo} (${design.location}) [${design.qtyAtLocation}]",
                          isSelected: true,
                        );
                      }).toList(),
                  onSelectionChanged: (selectedItems) {
                    final ids = selectedItems.map((e) => e.id).toList();
                    controller.onProductSelected(ids);
                  },
                ),
                // _buildPartySelector(context),
                const SizedBox(height: 20),

                // Product Selector
                // _buildProductSelector(),

                // Displaying Products and their details (Qty, Rate, Amount)
                Obx(
                  () => Column(
                    children:
                        controller.selectedProducts.map((product) {
                          return _buildProductCard(product);
                        }).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Validation checks
                    if ((controller.selectedPartyName.value ?? '').isEmpty ||
                        controller.selectedParty.value!.isEmpty) {
                      SnackbarUtil.showError('Please select a party');
                      return;
                    }

                    if (controller.selectedProducts.isEmpty) {
                      SnackbarUtil.showError(
                        'Please select atleast one design',
                      );
                      return;
                    }

                    // Check all selected products have quantity > 0
                    bool hasInvalidQuantity = false;
                    for (var product in controller.selectedProducts) {
                      final qty =
                          controller.qtyControllers[product]?.text ?? '';
                      if (qty.isEmpty ||
                          int.tryParse(qty) == null ||
                          int.parse(qty) <= 0) {
                        hasInvalidQuantity = true;
                        break;
                      }
                    }

                    if (hasInvalidQuantity) {
                      SnackbarUtil.showError('Please enter valid qty');
                      return;
                    }
                    // Check if entered qty > available stock
                    bool exceedsStock = false;
                    for (var designId in controller.selectedProducts) {
                      final design = controller.designList.firstWhere(
                        (d) => d.id == designId,
                        orElse:
                            () => StockList(
                              designNo: '',
                              id: '0',
                              designId: '0',
                              locationid: '0',
                              location: '',
                              qtyAtLocation: '0',
                              folderName: '',
                              productId: '0',
                              rate: 0,
                            ),
                      );
                      final enteredQty =
                          int.tryParse(
                            controller.qtyControllers[designId]?.text ?? '0',
                          ) ??
                          0;
                      final availableQty =
                          int.tryParse(design.qtyAtLocation ?? '0') ?? 0;

                      if (enteredQty > availableQty) {
                        exceedsStock = true;
                        break;
                      }
                    }

                    if (exceedsStock) {
                      SnackbarUtil.showError(
                        'Stock Not availble,please recheck all designs',
                      );
                      return;
                    }
                    // Validate rate (must not be empty or 0)
                    bool hasInvalidRate = false;
                    for (var product in controller.selectedProducts) {
                      final rate =
                          controller.rateControllers[product]?.text ?? '';
                      if (rate.isEmpty ||
                          int.tryParse(rate) == null ||
                          int.parse(rate) <= 0) {
                        hasInvalidRate = true;
                        break;
                      }
                    }

                    if (hasInvalidRate) {
                      SnackbarUtil.showError(
                        'Please enter valid rate (whole number > 0)',
                      );
                      return;
                    }
                    // Prepare products data
                    List<Map<String, dynamic>> products = [];
                    for (var designId in controller.selectedProducts) {
                      var design = controller.designList.firstWhere(
                        (d) => d.id == designId,
                        orElse:
                            () => StockList(
                              designNo: '',
                              folderName: '',
                              id: '0',
                              designId: '0',
                              location: '',
                              qtyAtLocation: '0',
                              locationid: '0',
                              productId: '0',
                              rate: 0,
                            ),
                      );
                      var rate =
                          int.tryParse(
                            controller.rateControllers[designId]!.text,
                          ) ??
                          0;
                      products.add({
                        'design_id': design.designId,
                        'product_id': design.productId,
                        'quantity':
                            int.tryParse(
                              controller.qtyControllers[designId]?.text ?? '',
                            ) ??
                            0,
                        'location_id': int.tryParse(design.locationid) ?? 0,
                        'rate': rate,
                      });
                    }

                    // Call saveSalesEntry with all required parameters
                    controller.saveSalesEntry(
                      invoiceNo: controller.invoiceNo.value,
                      date: DateFormat(
                        'yyyy-MM-dd',
                      ).format(controller.selectedDate.value),
                      partyId: controller.selectedParty.value,
                      products: products,
                    );
                  },
                  child: const Text(
                    "Save Entry",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),

                // Challan Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    // Validation checks
                    if ((controller.selectedPartyName.value ?? '').isEmpty) {
                      SnackbarUtil.showError('Please select a party');
                      return;
                    }

                    if (controller.selectedProducts.isEmpty) {
                      SnackbarUtil.showError(
                        'Please select atleast one design',
                      );

                      return;
                    }

                    // Validate quantities
                    for (var product in controller.selectedProducts) {
                      final qty =
                          controller.qtyControllers[product]?.text ?? '';
                      if (qty.isEmpty ||
                          int.tryParse(qty) == null ||
                          int.parse(qty) <= 0) {
                        SnackbarUtil.showError(
                          'Please enter valid quantity for all designs',
                        );

                        return;
                      }
                    }

                    // Validate rates
                    for (var product in controller.selectedProducts) {
                      final rate =
                          controller.rateControllers[product]?.text ?? '';
                      if (!RegExp(r'^[1-9]\d*$').hasMatch(rate)) {
                        SnackbarUtil.showError(
                          'Please enter valid rate (whole number > 0)',
                        );
                        return;
                      }
                    }
                    // Check stock vs entered qty
                    for (var designId in controller.selectedProducts) {
                      final design = controller.designList.firstWhere(
                        (d) => d.id == designId,
                        orElse:
                            () => StockList(
                              designNo: '',
                              id: '0',
                              designId: '0',
                              locationid: '0',
                              location: '',
                              qtyAtLocation: '0',
                              folderName: '',
                              productId: '0',
                              rate: 0,
                            ),
                      );
                      final enteredQty =
                          int.tryParse(
                            controller.qtyControllers[designId]?.text ?? '0',
                          ) ??
                          0;
                      final availableQty =
                          int.tryParse(design.qtyAtLocation ?? '0') ?? 0;

                      if (enteredQty > availableQty) {
                        SnackbarUtil.showError(
                          'Entered quantity for ${design.designNo} (${design.location}) exceeds available stock ($availableQty)',
                        );

                        return;
                      }
                    }

                    ///
                    String invoiceNo = controller.invoiceNo.value;
                    String? partyName = controller.selectedPartyName.value;
                    List<Map<String, dynamic>> products =
                        controller.selectedProducts.map((designId) {
                          final design = controller.designList.firstWhere(
                            (d) => d.id == designId,
                            orElse:
                                () => StockList(
                                  designNo: '',
                                  folderName: '',
                                  id: '0',
                                  designId: '0',
                                  location: '',
                                  qtyAtLocation: '0',
                                  locationid: '0',
                                  productId: '0',
                                  rate: 0,
                                ),
                          );
                          return {
                            'design_id': design.designId,
                            'designNo': design.designNo ?? 'N/A',
                            'brand': design.folderName ?? 'N/A',
                            'location': design.location ?? 'N/A',
                            'product_name':
                                "${design.designNo} (${design.location})",
                            'quantity':
                                controller.qtyControllers[designId]?.text ??
                                '0',
                            'rate':
                                controller.rateControllers[designId]?.text ??
                                '0',
                            'amount': controller.amounts[designId] ?? 0,
                            'product_id': design.productId,
                            'location_id': int.tryParse(design.locationid) ?? 0,
                          };
                        }).toList();
                    // Save sales entry first
                    controller.saveSalesEntry(
                      invoiceNo: invoiceNo,
                      date: DateFormat(
                        'yyyy-MM-dd',
                      ).format(controller.selectedDate.value),
                      partyId: controller.selectedParty.value,
                      products:
                          products
                              .map(
                                (p) => {
                                  'design_id': p['design_id'],
                                  'product_id': p['product_id'],
                                  'quantity': int.tryParse(p['quantity']) ?? 0,
                                  'rate': int.tryParse(p['rate']) ?? 0,
                                  'location_id': p['location_id'],
                                },
                              )
                              .toList(),
                    );
                    controller.printSalesEntry(invoiceNo, partyName, products);
                  },
                  child: const Text(
                    "Print Challan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      globalKey: GlobalKey(),
    );
  }

  // Date Selector UI
  Widget _buildDateSelector(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
        child: Row(
          children: [
            Text(
              "Invoice No: ${controller.invoiceNo.value}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textBlackDark,
              ),
            ),
            Spacer(),
            Row(
              children: [
                Text(
                  "Date: ${DateFormat('dd-MM-yyyy').format(controller.selectedDate.value)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlackDark,
                  ),
                ),

                GestureDetector(
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryColor,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.selectedDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) controller.selectedDate.value = picked;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Invoice Number UI
  Widget _buildInvoiceNo() {
    return ListTile(
      title: Text(
        "Invoice No: ${controller.invoiceNo.value}",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textBlackDark,
        ),
      ),
    );
  }

  // Party Selector UI (dropdown)
  Widget _buildPartySelector(BuildContext context) {
    return GestureDetector(
      onTap: () {
        DropDownState(
          dropDown: DropDown(
            data:
                controller.partyList
                    .map((p) => SelectedListItem<String>(data: p.partyName))
                    .toList(),
            bottomSheetTitle: const Text(
              "Select Party",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onSelected: (list) {
              final party = list.first.data;
              controller.selectedPartyName.value = party;
              controller.selectedParty.value = controller.partyMap[party] ?? "";
            },
          ),
        ).showModal(context);
      },
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.selectedPartyName?.value ?? "Select Party",
                style: const TextStyle(fontSize: 16, color: AppColors.textGrey),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // Product Selector UI (multi-select)
  Widget _buildProductSelector() {
    return Card(
      color: AppColors.tableItem,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: MultiSelectDialogField<StockList>(
          items:
              controller.designList
                  .map((p) => MultiSelectItem<StockList>(p, p.designNo))
                  .toList(),
          title: const Text(
            "Select Design",
            style: TextStyle(color: AppColors.textBlackDark),
          ),
          buttonText: const Text(
            "Choose Designs",
            style: TextStyle(color: AppColors.textGrey),
          ),
          initialValue:
              controller.designList
                  .where(
                    (design) =>
                        controller.selectedProducts.contains(design.designNo),
                  )
                  .toList(),
          onConfirm: (List<StockList> selectedDesigns) {
            controller.onProductSelected(
              selectedDesigns.map((design) => design.designNo).toList(),
            );
          },
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.primaryColor),
          ),
        ),
      ),
    );
  }

  // Product Card UI (for displaying product, qty, rate, and amount)
  Widget _buildProductCard(String uniqueId) {
    final design = controller.designList.firstWhere(
      (d) => d.id == uniqueId,
      orElse:
          () => StockList(
            designNo: 'Unknown',
            folderName: '',
            id: '0',
            designId: '0',
            location: 'Unknown',
            qtyAtLocation: '0',
            locationid: '0',
            productId: '0',
            rate: 0,
          ),
    );
    return Card(
      color: AppColors.tableItem,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${design.designNo} (${design.location})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textBlackDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQtySelector(uniqueId),
                Spacer(),
                _buildRateInput(uniqueId),
                Spacer(),
                _buildAmountDisplay(uniqueId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Quantity Selector with + / - buttons
  Widget _buildQtySelector(String uniqueId) {
    return SizedBox(
      width: Get.width * 0.25,
      child: TextFormField(
        controller: controller.qtyControllers[uniqueId],
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          labelText: "Qty",
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => controller.calculateAmount(uniqueId),
      ),
    );
  }

  // Rate Input Field for each product
  Widget _buildRateInput(String uniqueId) {
    return SizedBox(
      width: Get.width * 0.25,
      child: TextFormField(
        controller: controller.rateControllers[uniqueId],
        decoration: const InputDecoration(
          labelText: "Rate",
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => controller.calculateAmount(uniqueId),
      ),
    );
  }

  // Displaying Amount for each product
  Widget _buildAmountDisplay(String uniqueId) {
    return SizedBox(
      width: Get.width * 0.25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amount",
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          Text(
            "₹ ${controller.amounts[uniqueId] ?? 0}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textBlackDark,
            ),
          ),
        ],
      ),
    );
  }
}
