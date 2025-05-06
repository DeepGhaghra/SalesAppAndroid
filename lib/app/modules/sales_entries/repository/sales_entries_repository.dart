import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/service/supabase_service.dart';
import '../model/PartyInfo.dart';

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
}
