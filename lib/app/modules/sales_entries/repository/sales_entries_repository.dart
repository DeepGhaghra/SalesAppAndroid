import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/service/supabase_service.dart';
import '../model/PartyInfo.dart';
import '../model/SalesEntry.dart';

class SalesEntriesRepository {
  final SupabaseService _supabaseService = SupabaseService();
  final supabase = Supabase.instance.client;

  Future<List<PartyInfo>> fetchParties() async {
    try {
      final response = await _supabaseService.fetchAll('parties');
      return response.map<PartyInfo>((p) => PartyInfo.fromJson(p)).toList();
    } catch (e) {
      print('Error in PartyRepository: $e');
      rethrow;
    }
  }

  Future<int> getTotalCount() async {
    try {
      return await _supabaseService.getTotalCount('parties');
    } catch (e) {
      print('Error in PartyRepository while getting total count: $e');
      rethrow;
    }
  }

  Future<String> generateInvoiceNo() async {
    const prefix = 'SH-';

    final response =
        await supabase
            .from('sales_entries')
            .select('invoiceno')
            .like('invoiceno', '$prefix%')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    int nextNumber = 1;

    if (response != null && response['invoiceno'] != null) {
      final lastInvoice = response['invoiceno'].toString(); // e.g., "SH-104"
      final match = RegExp(r'SH-(\d+)').firstMatch(lastInvoice);
      if (match != null) {
        final lastNumber = int.tryParse(match.group(1) ?? '0') ?? 0;
        nextNumber = lastNumber + 1;
      }
    }

    return '$prefix$nextNumber';
  }

  //Save sales entry and deduct stock
  Future<Map<String, dynamic>> saveSalesEntry(
    Map<String, dynamic> salesData,
  ) async {
    try {
      // Validate required fields
      if (salesData['date'] == null ||
          salesData['invoiceno'] == null ||
          salesData['party_id'] == null ||
          salesData['product_id'] == null ||
          salesData['quantity'] == null ||
          salesData['rate'] == null ||
          salesData['amount'] == null ||
          salesData['design_id'] == null) {
        throw Exception('Missing required fields in sales data');
      }
      // Convert types to match database schema
      final data = {
        'date': salesData['date'].toString(),
        'invoiceno': salesData['invoiceno'].toString(),
        'party_id': int.parse(salesData['party_id'].toString()),
        'product_id': int.parse(salesData['product_id'].toString()),
        'quantity': int.parse(salesData['quantity'].toString()),
        'rate': int.parse(salesData['rate'].toString()),
        'amount': int.parse(salesData['amount'].toString()),
        'design_id': int.parse(salesData['design_id'].toString()),
        'created_at': DateTime.now().toIso8601String(),
        'modified_at': DateTime.now().toIso8601String(),
      };
      final response =
          await supabase.from('sales_entries').insert(data).select().single();
      return response;
    } catch (e) {
      print('Error saving sales entry: $e');
      rethrow;
    }
  }

  Future<void> deductStock(int designId, int locationId, int quantity) async {
    // Fetch stock data for the product and location
    try {
      final stockData =
          await supabase
              .from('stock')
              .select()
              .eq('design_id', designId)
              .eq('location_id', locationId)
              .maybeSingle();

      // Check if stock exists
      if (stockData == null) {
        throw Exception(
          'No stock found for design: $designId at location: $locationId',
        );
      }
      final currentQuantity = stockData['quantity'] as int;
      if (currentQuantity < quantity) {
        throw Exception(
          'Insufficient stock. Available: $currentQuantity, Requested: $quantity',
        );
      }

      // Deduct quantity from stock
      if (currentQuantity >= quantity) {
        await _supabaseService.update('stock', stockData['id'], {
          'quantity': currentQuantity - quantity,
          'time_added': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error deducting stock: $e');
      rethrow;
    }
  }

  // Log stock transaction
  Future<void> logStockTransaction(Map<String, dynamic> transactionData) async {
    try {
      // Validate required fields
      if (transactionData['design_id'] == null ||
          transactionData['location_id'] == null ||
          transactionData['quantity'] == null ||
          transactionData['transaction_type'] == null) {
        throw Exception('Missing required fields in transaction data');
      }

      final data = {
        'design_id': int.parse(transactionData['design_id'].toString()),
        'location_id': int.parse(transactionData['location_id'].toString()),
        'quantity': int.parse(transactionData['quantity'].toString()),
        'transaction_type': transactionData['transaction_type'].toString(),
        'reference_id':
            transactionData['reference_id'] != null
                ? int.parse(transactionData['reference_id'].toString())
                : null,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _supabaseService.insert('stock_transactions', data);
    } catch (e) {
      print('Error logging stock transaction: $e');
      rethrow;
    }
  }

  Future<List<SalesInvoiceGroup>> fetchGroupedSales({
    String? partyName,
    String? date,
  }) async {
    try {
      final data = await supabase.rpc(
        'fetch_grouped_sales',
        params: {'party': partyName, 'd': date},
      );

      final list = data as List<dynamic>;
      return list
          .map((e) => SalesInvoiceGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception('Supabase RPC Error: $e');
    }
  }
}
