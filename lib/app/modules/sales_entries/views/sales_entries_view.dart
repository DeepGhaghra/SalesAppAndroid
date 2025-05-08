import 'package:drop_down_list/drop_down_list.dart';
import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:sales_app/app/modules/stock_view/model/StockList.dart';

import '../../../core/common/multi_select_drop_down.dart';
import '../../../core/common/search_drop_down.dart';
import '../../../core/utils/app_colors.dart';
import '../controllers/sales_entries_controller.dart';

class SalesEntriesView extends GetView<SalesEntriesController> {
  const SalesEntriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackGround,
      appBar: AppBar(
        title: const Text(
          'Sales Entry',
          style: TextStyle(color: AppColors.textBlackDark),
        ),
        backgroundColor: AppColors.screenBackGround,
        elevation: 0,
        centerTitle: true,
      ),
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
                  labelText: "Select Party",
                  hintText: "Select Party",

                  items:
                      controller.partyList.map((element) {
                        return Item(id: element.id, name: element.partyName);
                      }).toList(),

                  onItemSelected: (Item selectedItem) {
                    controller.selectedPartyName.value = selectedItem.name;
                    controller.selectedParty.value = selectedItem.id;
                    print("Selected Party ID: ${selectedItem.id}");
                    print(selectedItem.name);
                  },
                ),

                const SizedBox(height: 20),
                MultiSelectSearchDropdown(
                  labelText: "Select Designs",
                  items:
                      controller.designList.map((element) {
                        return MultiSelectItemModel(
                          id: element.designId,
                          name:
                              "${element.designNo} || ${element.location ?? 'N/A'} || ${element.qtyAtLocation?.toString() ?? '0'}",
                        );
                      }).toList(),
                  onSelectionChanged: (
                    List<MultiSelectItemModel> selectedItems,
                  ) {
                    controller.onProductSelected(
                      selectedItems.map((e) => e.id).toList(),
                    );
                  },
                  selectedItems:
                      controller.selectedProducts.map((designId) {
                        final design = controller.designList.firstWhere(
                          (d) => d.designId == designId,
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
                          id: designId,
                          name: "${design.designNo} (${design.location})",
                          isSelected: true,
                        );
                      }).toList(),
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
                      Get.snackbar(
                        'Error',
                        'Please select a party',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    if (controller.selectedProducts.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please select atleast one design',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
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
                      Get.snackbar(
                        'Error',
                        'Please enter valid qty',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    // Check if entered qty > available stock
                    bool exceedsStock = false;
                    for (var designId in controller.selectedProducts) {
                      final design = controller.designList.firstWhere(
                        (d) => d.designId == designId,
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
                      Get.snackbar(
                        'Warning',
                        'Stock Not availble,please recheck all designs',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange,
                        colorText: Colors.black,
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
                      Get.snackbar(
                        'Error',
                        'Please enter valid rate (whole number > 0)',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    // Prepare products data
                    List<Map<String, dynamic>> products = [];
                    for (var designId in controller.selectedProducts) {
                      var design = controller.designList.firstWhere(
                        (d) => d.designId == designId,
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
                  onPressed: () {
                    // Validation checks
                    if ((controller.selectedPartyName.value ?? '').isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please select a party',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    if (controller.selectedProducts.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please select atleast one design',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
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
                        Get.snackbar(
                          'Error',
                          'Please enter valid quantity for all designs',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }
                    }

                    // Validate rates
                    for (var product in controller.selectedProducts) {
                      final rate =
                          controller.rateControllers[product]?.text ?? '';
                      if (!RegExp(r'^[1-9]\d*$').hasMatch(rate)) {
                        Get.snackbar(
                          'Error',
                          'Please enter valid rate (whole number > 0)',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }
                    }
                    // Check stock vs entered qty
                    for (var designId in controller.selectedProducts) {
                      final design = controller.designList.firstWhere(
                        (d) => d.designId == designId,
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
                        Get.snackbar(
                          'Warning',
                          'Entered quantity for ${design.designNo} (${design.location}) exceeds available stock ($availableQty)',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange,
                          colorText: Colors.black,
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
                            (d) => d.designId == designId,
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
                            'design_id': designId,
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
                          };
                        }).toList();

                    // Call the print function
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
  Widget _buildProductCard(String designId) {
    final design = controller.designList.firstWhere(
      (d) => d.designId == designId,
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
                _buildQtySelector(designId),
                Spacer(),
                _buildRateInput(designId),
                Spacer(),
                _buildAmountDisplay(designId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Quantity Selector with + / - buttons
  Widget _buildQtySelector(String product) {
    return SizedBox(
      width: Get.width * 0.25,
      child: TextFormField(
        controller: controller.qtyControllers[product],
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          labelText: "Qty",
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => controller.calculateAmount(product),
      ),
    );
  }

  // Rate Input Field for each product
  Widget _buildRateInput(String product) {
    return SizedBox(
      width: Get.width * 0.25,
      child: TextFormField(
        controller: controller.rateControllers[product],
        decoration: const InputDecoration(
          labelText: "Rate",
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => controller.calculateAmount(product),
      ),
    );
  }

  // Displaying Amount for each product
  Widget _buildAmountDisplay(String product) {
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
            "₹ ${controller.amounts[product] ?? 0}",
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
