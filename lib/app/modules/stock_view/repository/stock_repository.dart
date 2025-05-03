import '../../../data/service/supabase_service.dart';
import '../model/StockList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockRepository {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<StockList>> fetchStockList() async {
    try {
      final response = await _supabase
          .from('stock')
          .select('*, products_design!inner(*), locations!inner(*)');
      return response.map<StockList>((p) => StockList.fromJson(p)).toList();
    } catch (e) {
      print('Error in StockRepository: $e');
      rethrow;
    }
  }

  Future<int> getTotalCount() async {
    try {
      return await _supabaseService.getTotalCount('stock');
    } catch (e) {
      print('Error in StockRepository while getting total count: $e');
      rethrow;
    }
  }
}
