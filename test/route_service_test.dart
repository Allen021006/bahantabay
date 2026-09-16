import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'route service rejects reads and saves without an authenticated session',
    () async {
      final client = SupabaseClient('https://example.invalid', 'test-key');
      addTearDown(client.dispose);
      final service = SupabaseRouteService(client);
      await expectLater(
        service.fetchRoutes('user-a'),
        throwsA(isA<RouteFailure>()),
      );
      await expectLater(
        service.saveRoute(
          'user-a',
          const RouteDraft(
            name: 'Private route',
            startLatitude: 15,
            startLongitude: 120,
            destinationLatitude: 16,
            destinationLongitude: 121,
          ),
        ),
        throwsA(isA<RouteFailure>()),
      );
    },
  );
}
