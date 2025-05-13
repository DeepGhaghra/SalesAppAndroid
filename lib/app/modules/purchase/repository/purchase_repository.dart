import '../../../data/service/supabase_service.dart';
import '../model/PurchaseList.dart';

class PurchaseRepository {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<Purchaselist>> fetchPurchase() async {
    try {
      final response = await _supabaseService.fetchAll('purchase');
      return response
          .map<Purchaselist>((p) => Purchaselist.fromJson(p))
          .toList();
    } catch (e) {
      print('Error in PurchaseRepository: $e');
      rethrow;
    }
  }

  Future<int> getTotalCount() async {
    try {
      return await _supabaseService.getTotalCount('purchase');
    } catch (e) {
      print('Error in PurchaseRepository while getting total count: $e');
      rethrow;
    }
  }
}
