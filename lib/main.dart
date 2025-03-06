import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sales_entries.dart';
import 'party_list.dart';
import 'product_list.dart';
import 'pricelist.dart';
import 'export_data.dart';
import 'pay_reminder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bnvwbcndpfndzgcrsicc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJudndiY25kcGZuZHpnY3JzaWNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0Nzg4NzIsImV4cCI6MjA1NjA1NDg3Mn0.YDEmWHZnsVrgPbf71ytIVm4IrOf9xTqzthlhluW_OLI',
  );
  runApp(const SalesEntryApp());
}

class SalesEntryApp extends StatelessWidget {
  const SalesEntryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Entry',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // Ensuring light mode
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const SalesEntryScreen(),
            ),
            _drawerItem(
              context,
              Icons.group,
              "Party List",
              const PartyListScreen(isOnline: true),
            ),
            _drawerItem(
              context,
              Icons.shopping_cart,
              "Product List",
              const ProductListScreen(isOnline: true),
            ),
            _drawerItem(
              context,
              Icons.price_check,
              "Price List",
              const PriceListScreen(),
            ),
            _drawerItem(
              context,
              Icons.upload_file,
              "Export Data",
              const ExportDataScreen(),
            ),
          ],
        ),
      ),
      body: _homeMenu(context),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }

  Widget _homeMenu(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      children: [
        _menuTile(
          context,
          "Daily Sales Entry",
          Icons.receipt,
          const SalesEntryScreen(),
        ),
        _menuTile(
          context,
          "Manage Parties",
          Icons.group,
          const PartyListScreen(isOnline: true),
        ),
        _menuTile(
          context,
          "Manage Products",
          Icons.shopping_cart,
          const ProductListScreen(isOnline: true),
        ),
        _menuTile(
          context,
          "Price List View",
          Icons.price_check,
          const PriceListScreen(),
        ),
        _menuTile(
          context,
          "Export Data",
          Icons.upload_file,
          const ExportDataScreen(),
        ),
        _menuTile(context, "Payment Reminder", Icons.payments, const PaymentReminderScreen()),
      ],
    );
  }

  Widget _menuTile(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
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
}
