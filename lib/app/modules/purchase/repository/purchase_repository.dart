import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/service/supabase_service.dart';
import '../model/PurchaseList.dart';

class PurchaseRepository {
  final SupabaseService _supabaseService = SupabaseService();
  final supabase = Supabase.instance.client;

  Future<List<Purchaselist>> fetchDesigns() async {
    try {
      final response = await _supabaseService.fetchAll('products_design');
      return response.map<Purchaselist>((item) {
        return Purchaselist(
          id: item['id'] as int?,
          designId: item['design_id'] as int? ?? item['id'] as int?,
          designNo: item['design_no'] as String? ?? 'No Design Number',

          date: '',
          quantity: null,
        );
      }).toList();
    } catch (e) {
      print('Error in PurchaseRepository: $e');
      rethrow;
    }
  }

  Future<List<Purchaselist>> fetchLocation() async {
    try {
      final response = await _supabaseService.fetchAll('locations');

      return response.map<Purchaselist>((item) {
        return Purchaselist(
          id: item['id'] as int?,
          locationId: item['location_id'] as int? ?? item['id'] as int?,
          locationName: item['name'] as String? ?? 'No Location Name',
          date: '',
          quantity: null,
          designNo: '',
        );
      }).toList();
    } catch (e) {
      print('Error in PurchaseRepository: $e');
      rethrow;
    }
  }

  Future<List<Purchaselist>> getAllPurchases() async {
    try {
      final data = await _supabaseService.fetchAll('purchase');
      return data.map((e) => Purchaselist.fromJson(e)).toList();
    } catch (e) {
      print('Error in PurchaseRepository: $e');
      rethrow;
    }
  }
}
