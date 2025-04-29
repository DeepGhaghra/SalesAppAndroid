import 'package:drop_down_list/drop_down_list.dart';
import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

import '../../../core/common/multi_select_drop_down.dart';
import '../../../core/common/serach_drop_down.dart';
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
                    controller.selectedParty.value =
                        controller.partyMap[selectedItem.name] ?? "";
                    print(selectedItem.name);
                  },
                ),

                const SizedBox(height: 20),
                MultiSelectSearchDropdown(
                  labelText: "Select Designs",
                  items:
                      controller.designList.map((element) {
                        return MultiSelectItemModel(name: element);
                      }).toList(),
                  onSelectionChanged: (
                    List<MultiSelectItemModel> selectedItems,
                  ) {
                    controller.onProductSelected(
                      selectedItems.map((e) {
                        return e.name;
                      }).toList(),
                    );
                  },
                  selectedItems:
                      controller.selectedProducts.map((element) {
                        return MultiSelectItemModel(
                          name: element,
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
                    // Your Save Logic
                  },
                  child: const Text(
                    "Save Entry",
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
        child: MultiSelectDialogField(
          items:
              controller.designList.map((p) => MultiSelectItem(p, p)).toList(),
          title: const Text(
            "Select Products",
            style: TextStyle(color: AppColors.textBlackDark),
          ),
          buttonText: const Text(
            "Choose Products",
            style: TextStyle(color: AppColors.textGrey),
          ),
          initialValue: controller.selectedProducts,
          onConfirm: controller.onProductSelected,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.primaryColor),
          ),
        ),
      ),
    );
  }

  // Product Card UI (for displaying product, qty, rate, and amount)
  Widget _buildProductCard(String product) {
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
              product,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textBlackDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQtySelector(product),
                Spacer(),
                _buildRateInput(product),
                Spacer(),
                _buildAmountDisplay(product),
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
