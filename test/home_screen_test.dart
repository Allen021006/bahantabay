import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'support/fake_route_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/features/flood_reports/presentation/widgets/flood_report_entry.dart';
import 'package:bahantabay/features/home/presentation/screens/home_screen.dart';
import 'package:bahantabay/features/routes/presentation/widgets/route_card.dart';
import 'package:bahantabay/features/routes/presentation/screens/add_route_screen.dart';

Widget _testApp({
  required bool isGuest,
  String? email,
  bool showDemoData = true,
  Future<void> Function()? onReturnToAuth,
  RouteService? routeService,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: HomeScreen(
      isGuest: isGuest,
      email: email,
      showDemoData: showDemoData,
      userId: isGuest ? null : 'user-a',
      routeService:
          routeService ??
          (FakeRouteService()
            ..routes = showDemoData
                ? [exampleRoute(), exampleRoute(name: 'Work route')]
                : []),
      onReturnToAuth: onReturnToAuth ?? () async {},
    ),
  );
}

void main() {
  testWidgets('signed-in user opens Add Route and returns without saving', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isGuest: false));
    await tester.tap(find.text('Add route'));
    await tester.pumpAndSettle();
    expect(find.byType(AddRouteScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddRouteScreen), findsNothing);
    expect(find.text('Saved routes'), findsOneWidget);
    expect(find.byType(RouteCard), findsNWidgets(2));
  });

  testWidgets('Home List View fits the approved phone proportions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(isGuest: false, email: 'commuter@example.com'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in Home shell renders saved routes and demo reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(isGuest: false, email: 'commuter@example.com'),
    );
    await tester.pump();

    expect(find.byTooltip('Account menu'), findsOneWidget);
    expect(find.byType(SegmentedButton<HomeView>), findsOneWidget);
    expect(find.text('Saved routes'), findsOneWidget);
    expect(find.text('Nearby flood reports'), findsOneWidget);
    expect(find.byType(RouteCard), findsNWidgets(2));
    expect(find.byType(FloodReportEntry), findsNWidgets(2));
    expect(find.text('School route'), findsOneWidget);
    expect(find.text('Fiesta Community'), findsOneWidget);
    expect(find.text('Add route'), findsOneWidget);
    expect(find.text('Report Flood'), findsOneWidget);
  });

  testWidgets('guest Home disables write actions', (tester) async {
    final service = FakeRouteService();
    await tester.pumpWidget(_testApp(isGuest: true, routeService: service));

    final addRoute = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Add route'),
    );
    final reportFlood = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );

    expect(addRoute.onPressed, isNull);
    expect(reportFlood.onPressed, isNull);
    expect(find.byType(RouteCard), findsNWidgets(2));
    expect(service.fetchCalls, 0);
    expect(service.saveCalls, 0);
  });

  testWidgets('List and Map segments change one Home screen state', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isGuest: false));

    await tester.tap(find.text('Map'));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Saved routes'), findsNothing);

    await tester.tap(find.text('List'));
    await tester.pump();

    expect(find.text('Saved routes'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('Home Map renders route, flood markers, and warning card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(isGuest: true));
    await tester.tap(find.text('Map'));
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byKey(const Key('route-start-marker')), findsOneWidget);
    expect(find.byKey(const Key('route-destination-marker')), findsOneWidget);
    expect(find.byKey(const ValueKey('flood-marker-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('flood-marker-1')), findsOneWidget);
    expect(
      find.byKey(const Key('selected-route-warning-card')),
      findsOneWidget,
    );
    expect(find.text('WARNING'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Report Flood'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in account menu shows approved options', (tester) async {
    await tester.pumpWidget(
      _testApp(isGuest: false, email: 'commuter@example.com'),
    );

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();

    expect(find.text('commuter@example.com'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Switch account'), findsOneWidget);
  });

  testWidgets('guest account menu offers authentication', (tester) async {
    await tester.pumpWidget(_testApp(isGuest: true));

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();

    expect(find.text('Guest session'), findsOneWidget);
    expect(find.text('Sign in / Create account'), findsOneWidget);
  });

  testWidgets('Home uses sensible route and report empty states', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isGuest: false, showDemoData: false));
    await tester.pump();

    expect(find.text('No saved routes yet.'), findsOneWidget);
    expect(find.text('No nearby flood reports.'), findsOneWidget);
    expect(find.byType(RouteCard), findsNothing);
    expect(find.byType(FloodReportEntry), findsNothing);
  });

  testWidgets(
    'signed-in routes load, fail with retry, then show an empty state',
    (tester) async {
      final pending = Completer<List<SavedRoute>>();
      final service = FakeRouteService()..onFetch = (_) => pending.future;
      await tester.pumpWidget(_testApp(isGuest: false, routeService: service));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('School route'), findsNothing);
      pending.completeError(Exception('private technical detail'));
      await tester.pump();
      expect(
        find.text('Could not load your routes. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private technical'), findsNothing);
      service.onFetch = null;
      await tester.tap(find.text('Retry routes'));
      await tester.pump();
      expect(find.text('No saved routes yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'successful save returns Home, refreshes routes and uses saved map points',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeRouteService();
      await tester.pumpWidget(_testApp(isGuest: false, routeService: service));
      await tester.pump();
      await tester.tap(find.text('Add route'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'My saved route',
      );
      final map = find.byKey(const Key('add-route-map'));
      await tester.ensureVisible(map);
      await tester.tapAt(tester.getCenter(map) - const Offset(60, 30));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(tester.getCenter(map) + const Offset(60, 30));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PolylineLayer), findsOneWidget);
      await tester.ensureVisible(find.text('Save route'));
      await tester.tap(find.text('Save route'));
      await tester.pumpAndSettle();
      expect(find.byType(AddRouteScreen), findsNothing);
      expect(service.saveCalls, 1);
      expect(service.fetchCalls, 2);
      expect(service.lastDraft!.name, 'My saved route');
      expect(find.text('My saved route'), findsOneWidget);
      expect(find.text('Status not assessed'), findsOneWidget);
      expect(find.text('SAFE'), findsNothing);
      await tester.tap(find.text('Map'));
      await tester.pump();
      final line = tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single;
      expect(line.points.first.latitude, service.routes.single.startLatitude);
      expect(
        line.points.last.longitude,
        service.routes.single.destinationLongitude,
      );
      expect(find.text('My saved route'), findsOneWidget);
    },
  );
}
