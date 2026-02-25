import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/global_controller.dart';

import 'base_image.dart';

class CommonAppBar extends GetView<GlobalController> implements PreferredSizeWidget {
  final String title;

  const CommonAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      title: Text(title),
      actions: [
        GestureDetector(
          onTap: () => _showShopPopup(context),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Obx(() {
              final shop = controller.selectedShop;
              return BaseImageView(
                imageUrl: "",
                nameLetters: shop?.name ?? "NA",
                width: 50,
                height: 50,
                fontSize: 16,
              );
            }),
          ),
        )
      ],
    );
  }

  void _showShopPopup(BuildContext context) {
    final controller = Get.find<GlobalController>();

    showDialog(
      context: context,
      builder: (_) {
        String? selectedShopId = controller.selectedShopId.value;

        return AlertDialog(
          title: const Text("Select Shop"),
          content: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedShopId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    selectedShopId = val;
                  },
                  items: controller.shopList.map((shop) {
                    return DropdownMenuItem(
                      value: shop.id,
                      child: Row(
                        children: [
                          BaseImageView(
                            imageUrl: "",
                            nameLetters: shop.name,
                            width: 40,
                            height: 40,
                            fontSize: 14,
                          ),
                          const SizedBox(width: 12),
                          Text(shop.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedShopId != null) {
                  controller.selectShop(selectedShopId!);
                  Get.back();
                }
              },
              child: const Text("Switch"),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
