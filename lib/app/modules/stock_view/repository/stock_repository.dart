import '../../../data/service/supabase_service.dart';
import '../model/StockList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockRepository {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<StockList>> fetchStockList() async {
    try {
      final response = await _supabase.from('stock').select('''
          *, products_design!inner(*,
            product_head:product_head_id(*,
            folder:folder_id(folder_name))
          ),
          locations!inner(*)
        ''');
      return response.map<StockList>((p) => StockList.fromJson(p)).toList();
    } catch (e) {
      print('Error in StockRepository: $e');
      rethrow;
    }
  }

  Future<List<StockList>> fetchDesigns() async {
    try {
      final response = await _supabaseService.fetchAll('products_design');
      return response.map<StockList>((item) {
        return StockList(
          id: item['id'] as String? ?? '0',
          designId: item['design_id'] ?? item['id'] as String?,
          designNo: item['design_no'] as String? ?? 'No Design Number',
          locationid: '',
          location: '',
          qtyAtLocation: '',
          folderName: '',
          productId: '',
          rate: 0,
        );
      }).toList();
    } catch (e) {
      print('Error in PurchaseRepository: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLocations() async {
    final result = await _supabaseService.fetchAll('locations');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> addLocation(String name) async {
    await _supabaseService.insert('locations', {'name': name});
  }

  Future<void> updateLocation(int id, String name) async {
    await _supabaseService.update('locations', id, {
      'name': name,
      'modified_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
Future<void> updateDesign(int id, String name) async {
    await _supabaseService.update('products_design', id, {
      'design_no': name,
    });
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
