import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:sales_app/app/core/common/base_screen.dart';

import '../../../core/common/app_bar.dart';
import '../../../core/common/app_drawer.dart';
import '../../../routes/app_pages.dart';

import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      body: _homeMenu(context),
      globalKey: GlobalKey(),
      nameOfScreen: "Dashboard",
    );
  }
}

Widget _homeMenu(BuildContext context) {
  // Get screen width
  double screenWidth = MediaQuery.of(context).size.width;

  // Automatically adjust crossAxisCount based on screen width
  int crossAxisCount =
      screenWidth > 600 ? 5 : 3; // For tablets or larger screens, use 4 columns

  return GridView.count(
    crossAxisCount: crossAxisCount,
    padding: const EdgeInsets.all(16),
    children: [
      _menuTile(context, "Stock View", Icons.inventory_2, Routes.STOCKVIEW),
      _menuTile(context, "Sales Entry", Icons.receipt, Routes.SALESENTRIES),
      _menuTile(context, "Purchase", Icons.list_alt_sharp, Routes.PURCHASE),
      _menuTile(context, "Manage Parties", Icons.group, Routes.PARTYLIST),
      _menuTile(
        context,
        "Product Heads",
        Icons.shopping_cart,
        Routes.PRODUCTLIST,
      ),
      _menuTile(context, "Price List", Icons.price_check, Routes.PRICELIST),
      _menuTile(context, "Export Data", Icons.upload_file, Routes.EXPORTDATA),
      _menuTile(
        context,
        "Payment Reminder",
        Icons.payments,
        Routes.PAYREMINDER,
      ),
      _menuTile(
        context,
        "Party Sales Target",
        Icons.document_scanner_sharp,
        Routes.PARTYSALESTARGET,
      ),
    ],
  );
}

Widget _menuTile(
  BuildContext context,
  String title,
  IconData icon,
  String routeName,
) {
  return Card(
    elevation: 4,
    child: InkWell(
      onTap: () {
        if (routeName.isNotEmpty) {
          Get.toNamed(routeName);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.blue),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
