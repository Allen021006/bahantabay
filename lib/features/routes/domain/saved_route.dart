
class RouteDraft {
  const RouteDraft({
    required this.name,
    required this.startLatitude,
    required this.startLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  final String name;
  final double startLatitude;
  final double startLongitude;
  final double destinationLatitude;
  final double destinationLongitude;

  Map<String, dynamic> toInsertMap() => {
    'name': name.trim(),
    'start_latitude': startLatitude,
    'start_longitude': startLongitude,
    'destination_latitude': destinationLatitude,
    'destination_longitude': destinationLongitude,
  };
}

class SavedRoute extends RouteDraft {
  const SavedRoute({
    required this.id,
    required this.userId,
    required super.name,
    required super.startLatitude,
    required super.startLongitude,
    required super.destinationLatitude,
    required super.destinationLongitude,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;

  factory SavedRoute.fromMap(Map<String, dynamic> map) => SavedRoute(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    name: map['name'] as String,
    startLatitude: (map['start_latitude'] as num).toDouble(),
    startLongitude: (map['start_longitude'] as num).toDouble(),
    destinationLatitude: (map['destination_latitude'] as num).toDouble(),
    destinationLongitude: (map['destination_longitude'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
