import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

import '../../../routes/app_pages.dart';

import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Sales Entry')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 28),
                  ),
                ],
              ),
            ),
            _drawerItem(
              context,
              Icons.receipt,
              "Sales Entry",
                Routes.SALESENTRIES
              // const SalesEntryScreen(),
            ),
            _drawerItem(
              context,
              Icons.group,
              "Party List",
                Routes.PARTYLIST
              // const PartyListScreen(isOnline: true),
            ),
            _drawerItem(
              context,
              Icons.shopping_cart,
              "Product List",
           Routes.PRODUCTLIST
              // const ProductListScreen(isOnline: true),
            ),
            _drawerItem(
              context,
              Icons.price_check,
              "Price List",
              Routes.PRICELIST
              // const PriceListScreen(),
            ),
            _drawerItem(
              context,
              Icons.upload_file,
              "Export Data",

              Routes.EXPORTDATA
            ),
            _drawerItem(
              context,
              Icons.folder,
              "Manage Party Folders",
             Routes.PARTYFOLDER
            ),
            _drawerItem(
              context,
              Icons.inventory_2,
              "Manage Stock",
                Routes.STOCKVIEW
            ),
          ],
        ),
      ),
      body: _homeMenu(context),
    );

  }
}

Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String routeName
    ) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () {
     Get.back();

Get.toNamed(routeName);

    },
  );
}

Widget _homeMenu(BuildContext context) {
  return GridView.count(
    crossAxisCount: 3,
    padding: const EdgeInsets.all(16),
    children: [
      _menuTile(
        context,
        "Daily Sales Entry",
        Icons.receipt,
          Routes.SALESENTRIES
        // const SalesEntryScreen(),
      ),
      _menuTile(
        context,
        "Manage Parties",
        Icons.group,
          Routes.PARTYLIST
        // const PartyListScreen(isOnline: true),
      ),
      _menuTile(
        context,
        "Product Heads",
        Icons.shopping_cart,
          Routes.PRODUCTLIST
        // const ProductListScreen(isOnline: true),
      ),
      _menuTile(
        context,
        "Price List View",
        Icons.price_check,
          Routes.PRICELIST
        // const PriceListScreen(),
      ),
      _menuTile(
        context,
        "Export Data",
        Icons.upload_file,
        Routes.EXPORTDATA
        // const ExportDataView(),
      ),
      _menuTile(
        context,
        "Payment Reminder",
        Icons.payments,
       Routes.PAYREMINDER
        // const PaymentReminderScreen(),
      ),
      _menuTile(
        context,
        "Party Sales Target",
        Icons.document_scanner_sharp,
        Routes.PARTYSALESTARGET
        // const PartySalesTargetScreen(),
      ),
      _menuTile(
        context,
        "Stock View",
        Icons.inventory_2,
      Routes.STOCKVIEW
        // const StockViewScreen(),
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

        if(routeName.isNotEmpty) {
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
//
