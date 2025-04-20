import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/party_list_controller.dart';


class PartyListView extends GetView<PartyListController> {
  const PartyListView({super.key});

  void _showAddPartyDialog(BuildContext context) {
    TextEditingController partyController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text("Add New Party"),
        content: TextField(
          controller: partyController,
          decoration: InputDecoration(hintText: "Enter Party Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => controller.addParty(partyController.text),
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String oldName) {
    TextEditingController partyController = TextEditingController(text: oldName);
    Get.dialog(
      AlertDialog(
        title: Text("Edit Party"),
        content: TextField(controller: partyController),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                controller.editParty(oldName, partyController.text),
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Party List")),
      body: Obx(() => Column(
        children: [
          if (!controller.isOnline.value)
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.redAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "You are offline! Showing cached data.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search Party",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => controller.searchController.value = value,
            ),
          ),
          Expanded(
            child: controller.partyList.isEmpty &&
                !controller.isOnline.value
                ? Center(
              child: Text(
                "You are offline. No cached data available.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: controller.filteredList.length,
              itemBuilder: (context, index) {
                final party = controller.filteredList[index];
                return Card(
                  margin:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(party),
                    leading: Icon(Icons.person, color: Colors.blue),
                    trailing: controller.isOnline.value
                        ? IconButton(
                      icon: Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _showEditDialog(party),
                    )
                        : Icon(Icons.lock, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      )),
      floatingActionButton: Obx(() =>
      controller.isOnline.value
          ? FloatingActionButton(
        onPressed: () => _showAddPartyDialog(context),
        child: Icon(Icons.add),
      )
          : SizedBox.shrink()),
    );
  }
}
