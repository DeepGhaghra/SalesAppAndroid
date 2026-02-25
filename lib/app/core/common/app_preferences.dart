import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';



class AppPreference {
  static final AppPreference _appPreference = AppPreference._internal();

  AppPreference._internal();

  static AppPreference get instance => _appPreference;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }



}
