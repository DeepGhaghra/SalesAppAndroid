
import 'package:drop_down_list/drop_down_list.dart';
import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

import '../controllers/sales_entries_controller.dart';

class SalesEntriesView extends GetView<SalesEntriesController> {
  const SalesEntriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Entry')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: ListView(
              children: [
                ListTile(
                  title: Text("Date: ${DateFormat('dd-MM-yyyy').format(controller.selectedDate.value)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.selectedDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) controller.selectedDate.value = picked;
                    },
                  ),
                ),
                ListTile(
                  title: Text("Invoice No: ${controller.invoiceNo.value}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                InkWell(
                  onTap: () {
                    DropDownState(
                      dropDown: DropDown(
                        data: controller.partyList
                            .map((p) => SelectedListItem<String>(data: p))
                            .toList(),
                        bottomSheetTitle: const Text("Select Party", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        onSelected: (list) {
                          final party = list.first.data;
                          controller.selectedPartyName?.value = party;
                          controller.selectedParty?.value = controller.partyMap[party]!;
                        },
                      ),
                    ).showModal(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(controller.selectedPartyName?.value ?? "Select Party", style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                MultiSelectDialogField(
                  items: controller.productList.map((p) => MultiSelectItem(p, p)).toList(),
                  title: const Text("Select Products"),
                  buttonText: const Text("Choose Products"),
                  initialValue: controller.selectedProducts,
                  onConfirm: controller.onProductSelected,
                ),
                const SizedBox(height: 10),
                Obx(() => Column(
                  children: controller.selectedProducts.map((product) {
                    return ListTile(
                      title: Text(product),
                      subtitle: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: controller.qtyControllers[product],
                              decoration: const InputDecoration(labelText: "Qty"),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => controller.calculateAmount(product),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: controller.rateControllers[product],
                              decoration: InputDecoration(
                                labelText: "Rate",
                                filled: true,
                                fillColor: controller.rateFieldColor[product] ?? Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => controller.calculateAmount(product),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Amount", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("₹ ${controller.amounts[product] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // KEEPING business logic in controller is recommended, but you may call the function here if needed
                  },
                  child: const Text("Save Entry"),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
