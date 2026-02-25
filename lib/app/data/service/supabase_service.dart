import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all rows from a table
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    try {
      final response = await _supabase.from(table).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all rows from $table: $e');
      rethrow;
    }
  }

  // Fetch a single row by ID
  Future<Map<String, dynamic>?> fetchById(String table, dynamic id) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching row by id from $table: $e');
      rethrow;
    }
  }

  // Insert a new row
  Future<void> insert(String table, Map<String, dynamic> data) async {
    try {
      await _supabase.from(table).insert(data);
    } catch (e) {
      print('Error inserting into $table: $e');
      rethrow;
    }
  }

  // Update a row by ID
  Future<void> update(String table, dynamic id, Map<String, dynamic> data) async {
    try {
      await _supabase.from(table).update(data).eq('id', id);
    } catch (e) {
      print('Error updating $table: $e');
      rethrow;
    }
  }

  // Delete a row by ID
  Future<void> delete(String table, dynamic id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
    } catch (e) {
      print('Error deleting from $table: $e');
      rethrow;
    }
  }

  // Fetch paginated results
  Future<List<Map<String, dynamic>>> fetchPaginated({
    required String table,
    required int page,
    required int pageSize,
  }) async {
    try {
      final startIndex = page * pageSize;
      final endIndex = (page + 1) * pageSize - 1;

      final response = await _supabase
          .from(table)
          .select()
          .range(startIndex, endIndex);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching paginated results from $table: $e');
      rethrow;
    }
  }

  // Get total row count of a table
  Future<int> getTotalCount(String table) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .count(); // Correct method for getting the count of rows

      return response.count ?? 0; // This will return the row count
    } catch (e) {
      print('Error getting total count from $table: $e');
      rethrow;
    }
  }

  // Fetch rows by a specific column value
  Future<List<Map<String, dynamic>>> fetchByField(
      String table, String field, dynamic value) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(field, value); // Add filter condition
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching rows by $field from $table: $e');
      rethrow;
    }
  }

  // Fetch rows with a "LIKE" filter (partial matching)
  Future<List<Map<String, dynamic>>> fetchLike(
      String table, String field, String pattern) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .ilike(field, '%$pattern%'); // Use LIKE filter
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching rows with LIKE filter from $table: $e');
      rethrow;
    }
  }

  // Bulk insert multiple rows
  Future<void> bulkInsert(String table, List<Map<String, dynamic>> data) async {
    try {
      await _supabase.from(table).insert(data);
    } catch (e) {
      print('Error bulk inserting into $table: $e');
      rethrow;
    }
  }

  // Check if a record exists by a specific field
  Future<bool> exists(String table, String field, dynamic value) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(field, value)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking if record exists in $table: $e');
      rethrow;
    }
  }

  // Soft delete by updating a "deleted" field
  Future<void> softDelete(String table, dynamic id) async {
    try {
      await _supabase.from(table).update({'deleted': true}).eq('id', id);
    } catch (e) {
      print('Error soft deleting from $table: $e');
      rethrow;
    }
  }
}
