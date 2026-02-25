import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/export_data_controller.dart';

class ExportDataView extends GetView<ExportDataController> {
  const ExportDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Sales Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  controller.startDate.value == null || controller.endDate.value == null
                      ? 'Select Date Range'
                      : 'Selected: ${DateFormat('dd-MM-yyyy').format(controller.startDate.value!)} to ${DateFormat('dd-MM-yyyy').format(controller.endDate.value!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => controller.selectDateRange(context),
              ),
              const SizedBox(height: 10),

              // Product Summary Section
              if (controller.productSummary.isNotEmpty) ...[
                const Text(
                  'Product Summary:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Card(
                  color: Colors.grey[100],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: controller.productSummary.entries
                          .map(
                            (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'No data found for the selected date range.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => controller.exportToExcel(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Export to Excel'),
              ),
            ],
          );
        }),
      ),
    );
  }
}
