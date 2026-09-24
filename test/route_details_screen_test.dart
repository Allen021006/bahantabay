import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'package:bahantabay/features/routes/domain/route_status.dart';
import 'package:bahantabay/features/routes/presentation/screens/route_details_screen.dart';
import 'support/fake_route_service.dart';

void main() {
  for (final status in RouteStatus.values) {
    testWidgets('Details displays supplied ${status.label} snapshot', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RouteDetailsScreen(route: exampleRoute(), status: status),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(status.label), findsOneWidget);
      expect(find.text('Status not assessed'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  final first = exampleRoute();
  final second = SavedRoute(
    id: 'route-2',
    userId: 'user-a',
    name: 'Market route',
    startLatitude: 15.16,
    startLongitude: 120.6,
    destinationLatitude: 15.17,
    destinationLongitude: 120.61,
    createdAt: DateTime.utc(2026, 9, 22),
  );

  for (final route in [first, second]) {
    testWidgets('displays supplied data and map for ${route.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RouteDetailsScreen(route: route),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(route.name), findsOneWidget);
      expect(
        find.text('${route.startLatitude}, ${route.startLongitude}'),
        findsOneWidget,
      );
      expect(
        find.text(
          '${route.destinationLatitude}, ${route.destinationLongitude}',
        ),
        findsOneWidget,
      );
      expect(find.text('Status not assessed'), findsOneWidget);
      for (final label in ['SAFE', 'WARNING', 'NOT PASSABLE']) {
        expect(find.text(label), findsNothing);
      }
      final points = [
        LatLng(route.startLatitude, route.startLongitude),
        LatLng(route.destinationLatitude, route.destinationLongitude),
      ];
      final line = tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single;
      expect(line.points, points);
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers.map((marker) => marker.point), points);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Destination'), findsOneWidget);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
      expect(map.options.initialCameraFit, isA<CameraFit>());
      for (final point in points) {
        expect(camera.visibleBounds.contains(point), isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final separation in [0.0, 0.00000001]) {
    testWidgets('map handles endpoint separation $separation', (tester) async {
      final route = SavedRoute(
        id: 'close-route',
        userId: 'user-a',
        name: 'Close endpoints',
        startLatitude: 15.15,
        startLongitude: 120.59,
        destinationLatitude: 15.15 + separation,
        destinationLongitude: 120.59 + separation,
        createdAt: DateTime.utc(2026, 9, 22),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RouteDetailsScreen(route: route),
        ),
      );
      await tester.pumpAndSettle();
      final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
      expect(camera.zoom.isFinite, isTrue);
      expect(camera.zoom, lessThanOrEqualTo(16));
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('long route name fits and scrolls at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final route = exampleRoute(
        name: List.filled(12, 'My long saved route name').join(' '),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RouteDetailsScreen(route: route),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(route.name), findsOneWidget);
      await tester.ensureVisible(find.byType(FlutterMap));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
