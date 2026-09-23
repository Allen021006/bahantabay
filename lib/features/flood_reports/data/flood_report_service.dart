import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/flood_report.dart';

class FloodReportFailure implements Exception {
  const FloodReportFailure(this.message);
  final String message;
}

abstract interface class FloodReportService {
  Future<List<FloodReport>> fetchReports();
  Future<void> submitReport(String userId, FloodReportDraft draft);
}

class SupabaseFloodReportService implements FloodReportService {
  SupabaseFloodReportService(this._client);
  final SupabaseClient _client;

  @override
  Future<List<FloodReport>> fetchReports() async {
    try {
      // Public reads are allowed by RLS for both anon and authenticated roles.
      final rows = await _client
          .from('flood_reports')
          .select(
            'id,latitude,longitude,flood_depth,road_status,notes,created_at',
          )
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map(FloodReport.fromMap).toList();
    } catch (_) {
      throw const FloodReportFailure(
        'Could not load flood reports. Please try again.',
      );
    }
  }

  @override
  Future<void> submitReport(String userId, FloodReportDraft draft) async {
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser?.id != userId ||
        _client.auth.currentUser?.isAnonymous == true) {
      throw const FloodReportFailure(
        'Please sign in again to submit a report.',
      );
    }
    if (!FloodReportDraft.validCoordinates(draft.latitude, draft.longitude)) {
      throw const FloodReportFailure('Select a valid location on the map.');
    }
    if ((draft.notes?.length ?? 0) > FloodReportDraft.maxNotesLength) {
      throw const FloodReportFailure(
        'Keep notes to 1,000 characters or fewer.',
      );
    }
    try {
      // Pin ownership to this session; the existing INSERT policy enforces it.
      // The database generates id and created_at.
      await _client.from('flood_reports').insert({
        ...draft.toInsertMap(),
        'reporter_id': userId,
      });
    } catch (_) {
      throw const FloodReportFailure(
        'Could not confirm submission. Your draft is still here. '
        'If the connection dropped, check Home before retrying to avoid a duplicate.',
      );
    }
  }
}
