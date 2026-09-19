import 'package:bahantabay/features/flood_reports/data/flood_report_service.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_depth.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_report.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';

FloodReport exampleFloodReport({
  String id = 'report-0',
  String? notes = 'Water covers the crossing.',
}) => FloodReport(
  id: id,
  reporterId: 'reporter-test-id',
  latitude: 15.1470,
  longitude: 120.5920,
  depth: FloodDepth.knee,
  roadStatus: RoadStatus.notPassable,
  notes: notes,
  createdAt: DateTime.utc(2026, 9, 17),
);

class FakeFloodReportService implements FloodReportService {
  List<FloodReport> reports = [];
  int fetchCalls = 0;
  int submitCalls = 0;
  String? lastUserId;
  FloodReportDraft? lastDraft;
  Future<List<FloodReport>> Function()? onFetch;
  Future<void> Function()? onSubmit;

  @override
  Future<List<FloodReport>> fetchReports() async {
    fetchCalls++;
    if (onFetch != null) return onFetch!();
    return List.of(reports);
  }

  @override
  Future<void> submitReport(String userId, FloodReportDraft draft) async {
    submitCalls++;
    lastUserId = userId;
    lastDraft = draft;
    if (onSubmit != null) await onSubmit!();
    reports.insert(
      0,
      FloodReport(
        id: 'new-report',
        reporterId: userId,
        latitude: draft.latitude,
        longitude: draft.longitude,
        depth: draft.depth,
        roadStatus: draft.roadStatus,
        notes: draft.notes,
        createdAt: DateTime.utc(2026, 9, 17),
      ),
    );
  }
}
