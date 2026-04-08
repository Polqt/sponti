import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/suggestions/model/suggestion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

abstract interface class SuggestionsRemoteDataSource {
  Future<List<SuggestionModel>> fetchMySuggestions();
  Future<SuggestionModel> fetchSuggestionById(String id);
  Future<void> insertSuggestion(SuggestionModel suggestion);
  Future<void> updateSuggestion(SuggestionModel suggestion);
  Future<void> deleteSuggestion(String id);
}

class SuggestionsRemoteDataSourceImpl implements SuggestionsRemoteDataSource {
  const SuggestionsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('You must be logged in to manage suggestions.');
    }
    return userId;
  }

  @override
  Future<List<SuggestionModel>> fetchMySuggestions() async {
    final response = await _client
        .from(SupabaseTables.suggestions)
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => SuggestionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SuggestionModel> fetchSuggestionById(String id) async {
    final response = await _client
        .from(SupabaseTables.suggestions)
        .select()
        .eq('id', id)
        .eq('user_id', _currentUserId)
        .single();

    return SuggestionModel.fromJson(response);
  }

  @override
  Future<void> insertSuggestion(SuggestionModel suggestion) async {
    await _client.from(SupabaseTables.suggestions).insert({
      'user_id': _currentUserId,
      'name': suggestion.name,
      'description': suggestion.description,
      'category': suggestion.category,
      'address': suggestion.address,
      'latitude': suggestion.latitude,
      'longitude': suggestion.longitude,
    });
  }

  @override
  Future<void> updateSuggestion(SuggestionModel suggestion) async {
    await _client
        .from(SupabaseTables.suggestions)
        .update({
          'name': suggestion.name,
          'description': suggestion.description,
          'category': suggestion.category,
          'address': suggestion.address,
          'latitude': suggestion.latitude,
          'longitude': suggestion.longitude,
        })
        .eq('id', suggestion.id)
        .eq('user_id', _currentUserId);
  }

  @override
  Future<void> deleteSuggestion(String id) async {
    await _client
        .from(SupabaseTables.suggestions)
        .delete()
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }
}
