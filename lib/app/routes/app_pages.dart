import 'package:get/get.dart';
import 'package:sales_app/app/modules/export_data/bindings/export_data_binding.dart';
import 'package:sales_app/app/modules/export_data/views/export_data_view.dart';
import 'package:sales_app/app/modules/party_folders/bindings/party_binding.dart';
import 'package:sales_app/app/modules/party_folders/views/party_view.dart';
import 'package:sales_app/app/modules/party_list/bindings/party_list_binding.dart';
import 'package:sales_app/app/modules/party_list/views/party_list_view.dart';
import 'package:sales_app/app/modules/party_sales_target/bindings/party_sales_target_binding.dart';
import 'package:sales_app/app/modules/party_sales_target/views/party_sales_target_view.dart';
import 'package:sales_app/app/modules/pay_reminders/bindings/pay_reminder_binding.dart';
import 'package:sales_app/app/modules/pay_reminders/views/pay_reminder_view.dart';
import 'package:sales_app/app/modules/price_list/bindings/price_list_binding.dart';
import 'package:sales_app/app/modules/price_list/views/price_list_view.dart';
import 'package:sales_app/app/modules/product_list/bindings/product_list_binding.dart';
import 'package:sales_app/app/modules/product_list/views/product_list_view.dart';
import 'package:sales_app/app/modules/sales_entries/bindings/sales_entries_binding.dart';
import 'package:sales_app/app/modules/sales_entries/controllers/sales_list_controller.dart';
import 'package:sales_app/app/modules/sales_entries/views/sales_entries_view.dart';
import 'package:sales_app/app/modules/sales_entries/views/sales_list_view.dart';
import 'package:sales_app/app/modules/stock_view/bindings/stock_binding.dart';
import 'package:sales_app/app/modules/stock_view/views/stock_view.dart';
import 'package:sales_app/app/modules/purchase/bindings/purchase_binding.dart';
import 'package:sales_app/app/modules/purchase/views/purchase_view.dart';
import 'package:sales_app/app/modules/stock_view/views/stocktransfer_view.dart';
import 'package:sales_app/app/modules/stock_view/views/addnewstock_view.dart';
import 'package:sales_app/app/modules/stock_view/views/location_view.dart';

import '../modules/Dashboard/bindings/dashboard_binding.dart';
import '../modules/Dashboard/views/dashboard_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.DASHBOARD;

  static final routes = [
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => DashboardView(),
      binding: DashboardBinding(),
    ),

    GetPage(
      name: _Paths.EXPORTDATA,
      page: () => ExportDataView(),
      binding: ExportDataBinding(),
    ),

    GetPage(
      name: _Paths.PARTYFOLDER,
      page: () => PartyView(),
      binding: PartyBinding(),
    ),

    GetPage(
      name: _Paths.PARTYLIST,
      page: () => PartyListView(),
      binding: PartyListBinding(),
    ),

    GetPage(
      name: _Paths.PARTYSALESTARGET,
      page: () => PartySalesTargetView(),
      binding: PartySalesTargetBinding(),
    ),

    GetPage(
      name: _Paths.PAYREMINDER,
      page: () => PayReminderView(),
      binding: PayReminderBinding(),
    ),

    GetPage(
      name: _Paths.PRODUCTLIST,
      page: () => ProductListView(),
      binding: ProductListBinding(),
    ),

    GetPage(
      name: _Paths.SALESENTRIES,
      page: () => SalesEntriesView(),
      binding: SalesEntriesBinding(),
    ),

    GetPage(
      name: _Paths.PRICELIST,
      page: () => PriceListView(),
      binding: PriceListBinding(),
    ),

    GetPage(
      name: _Paths.STOCKVIEW,
      page: () => StockViewScreen(),
      binding: StockBinding(),
    ),

    GetPage(
      name: _Paths.PURCHASE,
      page: () => PurchaseViewScreen(),
      binding: PurchaseBinding(),
    ),
    GetPage(
      name: _Paths.STOCKTRANSFER,
      page: () => StockTransferScreen(),
      binding: StockTransferBinding(),
    ),
    GetPage(
      name: _Paths.ADDNEWSTOCK,
      page: () => AddStockScreen(),
      binding: AddnewStockBinding(),
    ),
    GetPage(
      name: _Paths.LOCATIONS,
      page: () => LocationView(),
      binding: LocationBinding(),
    ),
    GetPage(
      name: _Paths.SALESLIST,
      page: () => SalesViewPage(),
      binding: SalesListBinding(),
    ),
  ];
}
