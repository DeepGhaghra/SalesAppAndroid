

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../utils/globle_controller.dart';
import 'app_bar.dart';
import 'app_drawer.dart';

class BaseScreen extends StatelessWidget {
  BaseScreen({super.key, required this.body, required this.globalKey, this.isVisibleModel = false, this.onItemSelected, this.onPlayCallBack , this.nameOfScreen});

  Widget body;

  final bool isVisibleModel;
  String? nameOfScreen;


  final Function(int index)? onItemSelected;
  final GlobalKey<ScaffoldState> globalKey;
  final VoidCallback? onPlayCallBack;

  final GlobalController globalController = Get.find();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

        appBar: CommonAppBar(
          title: nameOfScreen ?? "",
        ),
        drawer: AppDrawer(),
      resizeToAvoidBottomInset: true,
      key: globalKey,
      backgroundColor: Colors.white,

      // appBar: CustomAppBar(),
      body: body
    );
  }
}
