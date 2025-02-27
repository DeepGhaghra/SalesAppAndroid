import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final supabase = Supabase.instance.client;

class ConnectivityUtils {
  static StreamSubscription? _connectivitySubscription;
  static Timer? _debounceTimer;

  static void startInternetListening(VoidCallback onConnectivityRestored) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      print("🌍 Connectivity changed: $result");

      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 500), () async {
        bool hasInternet = await ConnectivityUtils.hasInternet();
        if (hasInternet) {
          print("✅ Internet restored, syncing data...");
          //await SyncUtils.syncAll();
          onConnectivityRestored(); // Callback to update UI if needed
        } else {
          print("🔴 Still offline...");
        }
      });
    });
  }

  static Future<bool> hasInternet() async {
    try {
      final results = await Future.wait([
        InternetAddress.lookup('1.1.1.1'),
        InternetAddress.lookup('8.8.8.8'),
        InternetAddress.lookup('8.8.4.4'),
      ]);
      return results.any(
        (result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty,
      );
    } catch (e) {
      print("⚠️ Internet check failed: $e");
      return false;
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
  }
}

/*class SyncUtils {
  static Future<void> syncAll() async {
    print("🔄 Syncing all data...");

    try {
      await syncUnsyncedParties();
      await syncUnsyncedProducts();
      await syncUnsyncedPriceList();
    } catch (e) {
      print("❌ Sync failed: $e");
    }
  }

  static Future<void> syncUnsyncedParties() async {
    print("🔄 Syncing party list...");

    final prefs = await SharedPreferences.getInstance();
    List<String> offlineUpdates = prefs.getStringList('unsynced_parties') ?? [];

    if (offlineUpdates.isEmpty) {
      print("No unsynced parties to sync.");
      return;
    }
    for (String update in offlineUpdates) {
      try {
        List<String> parts = update.split("||");
        if (parts.length == 2) {
          String oldPartyName = parts[0];
          String newPartyName = parts[1];

          final response =
              await supabase
                  .from('parties')
                  .select('id')
                  .ilike('partyname', oldPartyName)
                  .maybeSingle();

          if (response != null) {
            int partyId = response['id'];
            await supabase
                .from('parties')
                .update({'partyname': newPartyName})
                .eq('id', partyId);
            print("✅ Updated '$oldPartyName' to '$newPartyName'");
          } else {
            // If the party doesn't exist, insert it
            await supabase.from('parties').insert({'partyname': newPartyName});
            print("✅ Inserted new party: '$newPartyName'");
          }
        }
      } catch (e) {
        print("❌ Error syncing party update: $e");
      }
    }
    await prefs.remove('unsynced_parties');
  }

  static Future<void> syncUnsyncedProducts() async {
    print("🔄 Syncing product list...");
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> unsyncedProducts =
          prefs.getStringList('unsyncedProducts') ?? [];

      for (String productData in unsyncedProducts) {
        try {
          List<String> parts = productData.split("=>");
          if (parts.length == 2) {
            String productName = parts[0];
            double price = double.parse(parts[1]);

            await supabase.from('products').upsert({
              'productname': productName,
              'price': price,
            });

            print("✅ Synced product: $productName");
          }
        } catch (e) {
          print("❌ Error syncing product: $e");
        }
      }

      await prefs.remove('unsyncedProducts');
    } catch (e) {
      print("❌ Failed to sync products: $e");
    }
  }

  static Future<void> syncUnsyncedPriceList() async {
    print("🔄 Syncing price list...");
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> unsyncedPrices =
          prefs.getStringList('unsyncedPriceList') ?? [];

      for (String priceEntry in unsyncedPrices) {
        try {
          List<String> parts = priceEntry.split("=>");
          if (parts.length == 3) {
            String partyName = parts[0];
            String productName = parts[1];
            double price = double.parse(parts[2]);

            await supabase.from('pricelist').upsert({
              'partyname': partyName,
              'productname': productName,
              'price': price,
            });

            print("✅ Synced price for $productName under $partyName");
          }
        } catch (e) {
          print("❌ Error syncing price list entry: $e");
        }
      }

      await prefs.remove('unsyncedPriceList');
    } catch (e) {
      print("❌ Failed to sync price list: $e");
    }
  }
}
*/