import 'package:bahantabay/features/flood_reports/domain/flood_depth.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_report.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database row and insert payload map exact Phase 8 fields', () {
    final report = FloodReport.fromMap({
      'id': 'report-1',
      'reporter_id': 'reporter-1',
      'latitude': 15,
      'longitude': 120.5,
      'flood_depth': 'knee',
      'road_status': 'not_passable',
      'notes': '  Water at the crossing.  ',
      'created_at': '2026-09-17T03:00:00Z',
    });
    expect(report.id, 'report-1');
    expect(report.reporterId, 'reporter-1');
    expect(report.createdAt, DateTime.utc(2026, 9, 17, 3));
    expect(report.toInsertMap(), {
      'latitude': 15.0,
      'longitude': 120.5,
      'flood_depth': 'knee',
      'road_status': 'not_passable',
      'notes': 'Water at the crossing.',
    });
  });

  test('all supported observation codes round trip and unknown codes fail', () {
    expect(FloodDepth.values.map((depth) => depth.code), [
      'ankle',
      'knee',
      'waist',
      'chest',
    ]);
    for (final depth in FloodDepth.values) {
      expect(FloodDepth.fromCode(depth.code), depth);
    }
    expect(RoadStatus.passable.code, 'passable');
    expect(RoadStatus.notPassable.code, 'not_passable');
    for (final status in RoadStatus.values) {
      expect(RoadStatus.fromCode(status.code), status);
    }
    expect(() => FloodDepth.fromCode('unknown'), throwsFormatException);
    expect(() => RoadStatus.fromCode('SAFE'), throwsFormatException);
  });

  test(
    'blank optional notes become null and invalid coordinates are rejected',
    () {
      const draft = FloodReportDraft(
        latitude: 15,
        longitude: 120,
        depth: FloodDepth.ankle,
        roadStatus: RoadStatus.passable,
        notes: '   ',
      );
      expect(draft.toInsertMap()['notes'], isNull);
      expect(FloodReportDraft.validCoordinates(-90, 180), isTrue);
      expect(FloodReportDraft.validCoordinates(90, -180), isTrue);
      expect(FloodReportDraft.validCoordinates(91, 120), isFalse);
      expect(FloodReportDraft.validCoordinates(15, -181), isFalse);
      expect(FloodReportDraft.validCoordinates(double.nan, 120), isFalse);
      expect(FloodReportDraft.validCoordinates(15, double.infinity), isFalse);
    },
  );
}
