import 'flood_depth.dart';
import 'road_status.dart';

class FloodReportDraft {
  const FloodReportDraft({
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.roadStatus,
    this.notes,
  });

  // A client-side limit for concise public observations; the SQL column is text.
  static const maxNotesLength = 1000;
  final double latitude;
  final double longitude;
  final FloodDepth depth;
  final RoadStatus roadStatus;
  final String? notes;

  static bool validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  Map<String, dynamic> toInsertMap() {
    final trimmedNotes = notes?.trim();
    return {
      'latitude': latitude,
      'longitude': longitude,
      'flood_depth': depth.code,
      'road_status': roadStatus.code,
      'notes': trimmedNotes == null || trimmedNotes.isEmpty
          ? null
          : trimmedNotes,
    };
  }
}

class FloodReport extends FloodReportDraft {
  const FloodReport({
    required this.id,
    required this.reporterId,
    required super.latitude,
    required super.longitude,
    required super.depth,
    required super.roadStatus,
    super.notes,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final DateTime createdAt;

  factory FloodReport.fromMap(Map<String, dynamic> map) {
    final latitude = (map['latitude'] as num).toDouble();
    final longitude = (map['longitude'] as num).toDouble();
    if (!FloodReportDraft.validCoordinates(latitude, longitude)) {
      throw const FormatException('Invalid report coordinates.');
    }
    return FloodReport(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String,
      latitude: latitude,
      longitude: longitude,
      depth: FloodDepth.fromCode(map['flood_depth'] as String),
      roadStatus: RoadStatus.fromCode(map['road_status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
