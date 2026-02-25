import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:sales_app/app/core/common/base_screen.dart';
import 'package:sales_app/app/modules/sales_entries/controllers/sales_entries_controller.dart';
import 'package:sales_app/app/modules/sales_entries/controllers/sales_list_controller.dart';
import 'package:sales_app/app/modules/sales_entries/model/SalesEntry.dart';

class SalesViewPage extends GetView<SalesListController> {
  const SalesViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesEntriesController printController = Get.put(
      SalesEntriesController(),
    );

    return BaseScreen(
      globalKey: GlobalKey(),

      nameOfScreen: 'Sales List',
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        decoration: InputDecoration(
                          hintText: 'Search party name',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: controller.updatePartySearch,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onChanged: controller.updateDateSearch,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Table Header
                Container(
                  color: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 16, child: Text('Date')),
                      Expanded(flex: 60, child: Text('Party Name')),
                      Expanded(flex: 8, child: Text('Qty')),
                      Expanded(flex: 8, child: Text('Edit')),
                      Expanded(flex: 8, child: Text('Print')),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Table Content
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.sales.isEmpty) {
                      return Center(child: Text('No data found.'));
                    }
                    return ListView.builder(
                      itemCount: controller.sales.length,
                      itemBuilder: (context, index) {
                        final item = controller.sales[index];
                        print("Items list:$item");
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 16, child: Text(item.date)),
                              Expanded(flex: 60, child: Text(item.partyName)),
                              Expanded(
                                flex: 8,
                                child: Text('${item.totalQty}'),
                              ),
                              Expanded(
                                flex: 8,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed: () {
                                      // Edit action
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    tooltip: "Edit Invoice",
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.print,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final products = await controller
                                          .getProductsForInvoice(
                                            item.invoiceNo,
                                          );
                                      print(
                                        "invoiceno:${item.invoiceNo} ,party name :${item.partyName} ,products:$products",
                                      );
                                      printController.printSalesEntry(
                                        item.invoiceNo,
                                        item.partyName,
                                        products,
                                      );
                                    },
                                    tooltip: "Print Invoice",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
