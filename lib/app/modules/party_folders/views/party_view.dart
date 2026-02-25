import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/party_controller.dart';
// Update this import

class PartyView extends GetView<PartyController> {
  const PartyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Party Folders")),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.filteredParties.length,
                itemBuilder: (context, index) {
                  final party = controller.filteredParties[index];
                  return ExpansionTile(
                    title: Text(party['name'] ?? 'Unnamed Party'),
                    children: controller.folders.map((folder) {
                      final folderId = folder['id'];
                      final isSelected = controller.partyFolderMapping[party['id']]?.contains(folderId) ?? false;
                      return CheckboxListTile(
                        title: Text(folder['folder_name'] ?? 'Unnamed Folder'),
                        value: isSelected,
                        onChanged: (value) {
                          controller.toggleFolder(party['id'], folderId, value ?? false);
                        },
                      );
                    }).toList(),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Obx(() {
        return Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Search Party",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: controller.updateSearchQuery,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Filter by Folder",
                border: OutlineInputBorder(),
              ),
              value: controller.selectedFolderId.value,
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text("All Folders"),
                ),
                ...controller.folders.map(
                      (folder) => DropdownMenuItem<int>(
                    value: folder['id'],
                    child: Text(folder['folder_name']),
                  ),
                ),
              ],
              onChanged: controller.updateSelectedFolder,
            ),
          ],
        );
      }),
    );
  }
}
