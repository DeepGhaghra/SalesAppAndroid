import 'package:flutter/material.dart';

class AppKeys {
  static final AppKeys _appKeys = AppKeys._();

  AppKeys._();

  static AppKeys get instance => _appKeys;

  late GlobalKey<NavigatorState>? _navigatorKey;
  late GlobalKey<ScaffoldState>? _dashboardScaffoldKey;

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  GlobalKey<ScaffoldState>? get dashboardScaffoldKey => _dashboardScaffoldKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setDashboardScaffoldKey(GlobalKey<ScaffoldState> key) {
    _dashboardScaffoldKey = key;
  }
}
