import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'support/fake_route_service.dart';
import 'support/fake_flood_report_service.dart';
import 'support/flood_form_actions.dart';
import 'package:bahantabay/features/flood_reports/data/flood_report_service.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_report.dart';
import 'package:bahantabay/features/flood_reports/presentation/screens/report_flood_screen.dart';
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
  FloodReportService? floodReportService,
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
      floodReportService:
          floodReportService ??
          (FakeFloodReportService()
            ..reports = showDemoData
                ? [
                    exampleFloodReport(),
                    exampleFloodReport(id: 'report-1', notes: null),
                  ]
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

  testWidgets('signed-in Home shell renders saved routes and public reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(isGuest: false, email: 'commuter@example.com'),
    );
    await tester.pump();

    expect(find.byTooltip('Account menu'), findsOneWidget);
    expect(find.byType(SegmentedButton<HomeView>), findsOneWidget);
    expect(find.text('Saved routes'), findsOneWidget);
    expect(find.text('Flood reports'), findsOneWidget);
    expect(find.byType(RouteCard), findsNWidgets(2));
    expect(find.byType(FloodReportEntry), findsNWidgets(2));
    expect(find.text('School route'), findsOneWidget);
    expect(find.text('15.14700, 120.59200'), findsNWidgets(2));
    expect(find.text('Water covers the crossing.'), findsOneWidget);
    expect(find.text('reporter-test-id'), findsNothing);
    expect(find.text('Demo reports'), findsNothing);
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
    expect(find.byKey(const ValueKey('flood-marker-report-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('flood-marker-report-1')), findsOneWidget);
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
    expect(find.text('No flood reports yet.'), findsOneWidget);
    expect(find.byType(RouteCard), findsNothing);
    expect(find.byType(FloodReportEntry), findsNothing);
  });

  testWidgets(
    'signed-in routes load, fail with retry, then show an empty state',
    (tester) async {
      final pending = Completer<List<SavedRoute>>();
      final service = FakeRouteService()..onFetch = (_) => pending.future;
      await tester.pumpWidget(_testApp(isGuest: false, routeService: service));
      expect(find.bySemanticsLabel('Loading saved routes'), findsOneWidget);
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

  testWidgets(
    'guest loads public reports with loading, error, retry and empty states',
    (tester) async {
      final pending = Completer<List<FloodReport>>();
      final reports = FakeFloodReportService()..onFetch = () => pending.future;
      final routes = FakeRouteService();
      await tester.pumpWidget(
        _testApp(
          isGuest: true,
          routeService: routes,
          floodReportService: reports,
        ),
      );
      expect(find.byKey(const Key('flood-reports-loading')), findsOneWidget);
      expect(reports.fetchCalls, 1);
      expect(routes.fetchCalls, 0);
      pending.completeError(Exception('internal SQL data'));
      await tester.pump();
      await tester.ensureVisible(find.text('Retry flood reports'));
      expect(
        find.text('Could not load flood reports. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('internal SQL'), findsNothing);
      reports.onFetch = null;
      await tester.tap(find.text('Retry flood reports'));
      await tester.pump();
      expect(find.text('No flood reports yet.'), findsOneWidget);
      reports.reports = [exampleFloodReport()];
      await tester.ensureVisible(find.byTooltip('Refresh flood reports'));
      await tester.tap(find.byTooltip('Refresh flood reports'));
      await tester.pump();
      expect(find.byType(FloodReportEntry), findsOneWidget);
      expect(find.text('Water covers the crossing.'), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      expect(reports.submitCalls, 0);
    },
  );

  testWidgets(
    'successful report returns Home, refreshes entries and real map markers',
    (tester) async {
      usePhoneSize(tester);
      final reports = FakeFloodReportService();
      final routes = FakeRouteService()..routes = [exampleRoute()];
      await tester.pumpWidget(
        _testApp(
          isGuest: false,
          routeService: routes,
          floodReportService: reports,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Report Flood'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportFloodScreen), findsOneWidget);
      await fillFloodForm(tester);
      await submitFloodForm(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ReportFloodScreen), findsNothing);
      expect(reports.submitCalls, 1);
      expect(reports.fetchCalls, 2);
      expect(routes.fetchCalls, 1);
      expect(reports.lastDraft!.notes, '');
      await tester.ensureVisible(find.text('Flood reports'));
      expect(find.byType(FloodReportEntry), findsOneWidget);
      expect(find.textContaining('Knee-deep'), findsOneWidget);
      expect(find.text('user-a'), findsNothing);
      expect(find.text('Status not assessed'), findsOneWidget);
      await tester.tap(find.text('Map'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('flood-marker-new-report')),
        findsOneWidget,
      );
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      final reportMarker = markers.singleWhere(
        (marker) =>
            marker.child.key == const ValueKey('flood-marker-new-report'),
      );
      expect(reportMarker.point.latitude, reports.lastDraft!.latitude);
      expect(reportMarker.point.longitude, reports.lastDraft!.longitude);
      expect(find.text('Status not assessed'), findsOneWidget);
      expect(find.text('SAFE'), findsNothing);
      expect(find.text('WARNING'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
