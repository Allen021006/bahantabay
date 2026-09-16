import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the database row and omits server fields from insert data', () {
    final route = SavedRoute.fromMap({
      'id': 'route-1',
      'user_id': 'user-a',
      'name': ' School route ',
      'start_latitude': 15,
      'start_longitude': 120.58,
      'destination_latitude': 16.5,
      'destination_longitude': 121,
      'created_at': '2026-09-15T03:00:00Z',
    });
    expect(route.id, 'route-1');
    expect(route.userId, 'user-a');
    expect(route.createdAt, DateTime.utc(2026, 9, 15, 3));
    expect(route.toInsertMap(), {
      'name': 'School route',
      'start_latitude': 15.0,
      'start_longitude': 120.58,
      'destination_latitude': 16.5,
      'destination_longitude': 121.0,
    });
  });
}
