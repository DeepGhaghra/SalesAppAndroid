import '../../../data/service/supabase_service.dart';
import '../model/PriceList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceListRepository {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await Supabase.instance.client
        .from('product_head')
        .select(
          'id, product_name, product_rate',
        )
;
    final data = response as List;
    return data.cast<Map<String, dynamic>>();
  }
}
