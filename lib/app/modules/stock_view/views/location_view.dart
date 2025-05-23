import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales_app/app/core/utils/snackbar_utils.dart';
import 'package:sales_app/app/routes/app_pages.dart';

import '../controllers/location_controller.dart';

class LocationView extends GetView<LocationController> {
  const LocationView({super.key});
  void _showAddLocationDialog(BuildContext context) {
    controller.nameController.clear();
    Get.dialog(
      AlertDialog(
        title: Text("Add New Location"),
        content: TextField(
          controller: controller.nameController,
          decoration: InputDecoration(hintText: "Enter Location Name"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = controller.nameController.text.trim();
              if (name.isNotEmpty) {
                await controller.addLocation(name);
                Get.back();
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(int id, String currentName) {
    controller.nameController.text = currentName;
    Get.dialog(
      AlertDialog(
        title: Text("Edit Location"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(hintText: "Enter New Name"),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Editing this location will update all associated stock entries.",
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = controller.nameController.text.trim();
              if (name.isNotEmpty) {
                await controller.editLocation(id, name);
                Get.back();
              }
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Locations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.toNamed(Routes.STOCKVIEW),
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          itemCount: controller.locations.length,
          itemBuilder: (context, index) {
            final location = controller.locations[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              child: ListTile(
                title: Text(location['name']),
                leading: Icon(Icons.location_on, color: Colors.blue),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.green),
                  onPressed:
                      () => _showEditLocationDialog(
                        location['id'],
                        location['name'],
                      ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLocationDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
