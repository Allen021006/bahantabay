import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/features/routes/presentation/screens/add_route_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AddRouteScreen()),
    );
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save route'));
    await tester.tap(find.text('Save route'));
    await tester.pump();
  }

  testWidgets('Add Route renders fields and validates an empty draft', (
    tester,
  ) async {
    await openScreen(tester);
    expect(find.text('Route name'), findsOneWidget);
    expect(find.text('Start location'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await save(tester);
    expect(find.text('Enter a route name.'), findsOneWidget);
    expect(find.text('Select a starting point on the map.'), findsOneWidget);
    expect(find.text('Select a destination on the map.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'map taps select and replace endpoints; save keeps a local draft',
    (tester) async {
      await openScreen(tester);
      await tester.enterText(find.byType(TextFormField).first, 'School route');
      final mapFinder = find.byKey(const Key('add-route-map'));
      final center = tester.getCenter(mapFinder);
      await tester.tapAt(center - const Offset(60, 30));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Start'), findsOneWidget);
      await save(tester);
      expect(find.text('Select a destination on the map.'), findsOneWidget);
      await tester.ensureVisible(mapFinder);
      await tester.tapAt(tester.getCenter(mapFinder) + const Offset(60, 30));
      await tester.pump(const Duration(milliseconds: 400));
      final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(line.polylines.single.points, hasLength(2));
      final originalStart = line.polylines.single.points.first;

      await tester.tap(find.widgetWithText(TextFormField, 'Start location'));
      await tester.tapAt(tester.getCenter(mapFinder) - const Offset(80, 50));
      await tester.pump(const Duration(milliseconds: 400));
      final updatedLine = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(updatedLine.polylines.single.points.first, isNot(originalStart));
      expect(
        updatedLine.polylines.single.points.last,
        line.polylines.single.points.last,
      );
      await save(tester);
      expect(
        find.text('Route preview is ready. Saving is not available yet.'),
        findsOneWidget,
      );
      expect(find.byType(AddRouteScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
