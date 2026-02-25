import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../utils/global_controller.dart';

class AppDrawer extends GetView<GlobalController> {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),

                Obx(() {
                  final shops = controller.shopList;
                  final selectedId = controller.selectedShopId.value;

                  return DropdownButton<String>(
                    isExpanded: true,
                    value: selectedId,

                    style: TextStyle(color: Colors.black54),
                    hint: const Text('Select Shop'),
                    underline: SizedBox(),
                    onChanged: (value) {
                      if (value != null) controller.selectShop(value);
                    },
                    items:
                        shops.map((shop) {
                          return DropdownMenuItem<String>(
                            value: shop.id,
                            child: Text(
                              shop.name,
                              style: TextStyle(
                                fontWeight:
                                    shop.id == selectedId
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                  );
                }),
              ],
            ),
          ),
          _drawerItem(context, Icons.home, "Home", Routes.DASHBOARD),
          _drawerItem(context, Icons.inventory_2, "Stock", Routes.STOCKVIEW),
          _drawerItem(
            context,
            Icons.receipt,
            "Sales Entry",
            Routes.SALESENTRIES,
          ),
          _drawerItem(
            context,
            Icons.list_alt_sharp,
            "Purchase Entry",
            Routes.PURCHASE,
          ),
          _drawerItem(context, Icons.group, "Party List", Routes.PARTYLIST),
          //_drawerItem(context, Icons.shopping_cart, "Product List", Routes.PRODUCTLIST),
          _drawerItem(
            context,
            Icons.price_check,
            "Price List",
            Routes.PRICELIST,
          ),
          // _drawerItem(context, Icons.upload_file, "Export Data", Routes.EXPORTDATA),
          _drawerItem(
            context,
            Icons.folder,
            "Manage Party Folders",
            Routes.PARTYFOLDER,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        Get.toNamed(route);
      },
    );
  }
}
