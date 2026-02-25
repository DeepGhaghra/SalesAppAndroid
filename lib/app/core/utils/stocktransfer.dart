import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockTransferScreen extends StatefulWidget {
  @override
  _StockTransferScreenState createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  String? selectedDesign;
  String? selectedFromLocation;
  String? selectedToLocation;
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> designList = [];
  List<Map<String, dynamic>> locationList = [];

  @override
  void initState() {
    super.initState();
    _fetchDesigns();
    _fetchLocations();
  }

  Future<void> _fetchDesigns() async {
    final response = await Supabase.instance.client
        .from('products_design')
        .select('id, design_no');

    setState(() {
      designList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchLocations() async {
    final response = await Supabase.instance.client
        .from('locations')
        .select('id, name');

    setState(() {
      locationList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _transferStock() async {
    if (selectedDesign == null ||
        selectedFromLocation == null ||
        selectedToLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select all fields!')));
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter a valid quantity!')));
      return;
    }

    try {
      final productId = int.tryParse(selectedDesign ?? '0') ?? 0;
      final fromLocationId = int.tryParse(selectedFromLocation ?? '0') ?? 0;
      final toLocationId = int.tryParse(selectedToLocation ?? '0') ?? 0;
      // Check stock at source location
      final stockResponse =
          await Supabase.instance.client
              .from('stock')
              .select('quantity')
              .eq('design_id', productId)
              .eq('location_id', fromLocationId)
              .single();

      final availableQty = stockResponse['quantity'] ?? 0;
      if (availableQty < quantity) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Insufficient stock!')));
        return;
      }

      // Deduct stock from source
      await Supabase.instance.client
          .from('stock')
          .update({'quantity': availableQty - quantity})
          .match({'design_id': productId, 'location_id': fromLocationId});

      // Add stock to destination
      final toStockResponse =
          await Supabase.instance.client
              .from('stock')
              .select('quantity')
              .eq('design_id', productId)
              .eq('location_id', toLocationId)
              .maybeSingle();

      if (toStockResponse != null) {
        await Supabase.instance.client
            .from('stock')
            .update({'quantity': toStockResponse['quantity'] + quantity})
            .match({'design_id': productId, 'location_id': toLocationId});
      } else {
        await Supabase.instance.client.from('stock').insert({
          'design_id': productId,
          'location_id': toLocationId,
          'quantity': quantity,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock transferred successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stock Transfer")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Design Number Dropdown
            DropdownButtonFormField<String>(
              value: selectedDesign,
              hint: Text("Select Design Number"),
              items:
                  designList.map((design) {
                    return DropdownMenuItem<String>(
                      value: design['id'].toString(),
                      child: Text(design['design_no']),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedDesign = value),
            ),
            SizedBox(height: 10),

            // From Location Dropdown
            DropdownButtonFormField<String>(
              value: selectedFromLocation,
              hint: Text("From Location"),
              items:
                  locationList.map((location) {
                    return DropdownMenuItem<String>(
                      value: location['id'].toString(),
                      child: Text(location['name']),
                    );
                  }).toList(),
              onChanged:
                  (value) => setState(() => selectedFromLocation = value),
            ),
            SizedBox(height: 10),

            // To Location Dropdown
            DropdownButtonFormField<String>(
              value: selectedToLocation,
              hint: Text("To Location"),
              items:
                  locationList.map((location) {
                    return DropdownMenuItem<String>(
                      value: location['id'].toString(),
                      child: Text(location['name']),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedToLocation = value),
            ),
            SizedBox(height: 10),

            // Quantity Input
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _transferStock,
              child: Text("Transfer Stock"),
            ),
          ],
        ),
      ),
    );
  }
}
