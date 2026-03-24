import 'package:sponti/core/constants/api_constants.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/suggestions/model/suggestion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SuggestionsRepository {
  const SuggestionsRepository(this._client);

  final supabase.SupabaseClient _client;

  Future<void> submitSuggestion(SuggestionModel suggestion) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('you need to be signed in to suggest a spot');
    }

    final payload = {
      'user_id': user.id,
      'name': suggestion.name,
      'description': suggestion.description,
      'category': suggestion.category,
      'address': suggestion.address,
      'latitude': suggestion.latitude,
      'longitude': suggestion.longitude,
    };

    try {
      await _client.from(ApiConstants.suggestionsTable).insert(payload);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('failed to submit suggestion: $e');
    }
  }
}
