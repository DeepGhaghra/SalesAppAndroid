import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityUtils {
  static StreamSubscription? _connectivitySubscription;
  static Timer? _debounceTimer;

  static void startInternetListening(VoidCallback onConnectivityRestored) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {

      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 500), () async {
        bool hasInternet = await ConnectivityUtils.hasInternet();
        if (hasInternet) {
         
          onConnectivityRestored(); // Notify the UI to switch to online mode
        } else {
        }
      });
    });
  }

  static Future<bool> hasInternet() async {
    try {
      final results = await Future.wait([
        InternetAddress.lookup('1.1.1.1'),
        InternetAddress.lookup('8.8.8.8'),
      ]);
      return results.any(
        (result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty,
      );
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
  }
}
