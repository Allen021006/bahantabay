import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/saved_route.dart';

class RouteFailure implements Exception {
  const RouteFailure(this.message);
  final String message;
}

abstract interface class RouteService {
  Future<List<SavedRoute>> fetchRoutes(String userId);
  Future<void> saveRoute(String userId, RouteDraft draft);
}

class SupabaseRouteService implements RouteService {
  SupabaseRouteService(this._client);
  final SupabaseClient _client;

  void _requireUser(String userId) {
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser?.id != userId) {
      throw const RouteFailure('Your session changed. Please sign in again.');
    }
  }

  @override
  Future<List<SavedRoute>> fetchRoutes(String userId) async {
    _requireUser(userId);
    try {
      final rows = await _client
          .from('routes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _requireUser(userId);
      return rows.map(SavedRoute.fromMap).toList();
    } on RouteFailure {
      rethrow;
    } catch (_) {
      throw const RouteFailure('Could not load your routes. Please try again.');
    }
  }

  @override
  Future<void> saveRoute(String userId, RouteDraft draft) async {
    _requireUser(userId);
    try {
      // Explicit ownership also prevents a draft crossing accounts if a token
      // changes during the request. RLS checks it against the request identity.
      await _client.from('routes').insert({
        ...draft.toInsertMap(),
        'user_id': userId,
      });
    } catch (_) {
      throw const RouteFailure(
        'Could not confirm the save. Check your connection and retry. '
        'If the connection dropped, check Home first to avoid a duplicate.',
      );
    }
  }
}
