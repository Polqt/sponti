import 'package:sponti/core/errors/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

/// Mixin providing common Supabase query execution with error handling.
///
/// Use this mixin in remote data source implementations to avoid duplicating
/// the try-catch boilerplate for PostgrestException handling.
mixin SupabaseQueryMixin {
  /// Executes a Supabase query with standardized error handling.
  ///
  /// Converts [PostgrestException] to appropriate app exceptions:
  /// - PGRST116 (no rows) -> [NotFoundException]
  /// - Other errors -> [ServerException]
  Future<T> executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundException();
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
