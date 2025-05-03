import '../../../data/service/supabase_service.dart';
import '../model/PartyInfo.dart';

class SalesEntriesRepository {
  final SupabaseService _supabaseService = SupabaseService();

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
}
