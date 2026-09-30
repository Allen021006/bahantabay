import 'package:bahantabay/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'package:bahantabay/features/routes/domain/route_status.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_depth.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';
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
import 'package:bahantabay/features/routes/presentation/screens/route_details_screen.dart';

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
                ? [
                    exampleRoute(),
                    exampleRoute(id: 'route-2', name: 'Work route'),
                  ]
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
  testWidgets('edit and delete an owned route return Home and refresh', (
    tester,
  ) async {
    usePhoneSize(tester);
    final service = FakeRouteService()..routes = [exampleRoute()];
    await tester.pumpWidget(_testApp(isGuest: false, routeService: service));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RouteCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit or delete route'));
    await tester.pumpAndSettle();
    expect(find.text('Edit route'), findsOneWidget);
    expect(find.text('School route'), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Updated route');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(service.updateCalls, 1);
    expect(service.saveCalls, 0);
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(find.text('Updated route'), findsOneWidget);
    expect(service.lastDraft!.startLatitude, exampleRoute().startLatitude);
    await tester.tap(find.byType(RouteCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit or delete route'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete route'));
    await tester.tap(find.text('Delete route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.deleteCalls, 0);
    await tester.tap(find.text('Delete route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(service.deleteCalls, 1);
    expect(find.byType(AddRouteScreen), findsNothing);
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(find.text('No saved routes yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final status in RouteStatus.values) {
    testWidgets('real List, Map and Details agree on ${status.label}', (
      tester,
    ) async {
      usePhoneSize(tester);
      final route = exampleRoute();
      final routes = FakeRouteService()..routes = [route];
      final reports = FakeFloodReportService();
      if (status != RouteStatus.clear) {
        reports.reports = [
          FloodReport(
            id: 'near-route',
            latitude: route.startLatitude,
            longitude: route.startLongitude,
            depth: FloodDepth.ankle,
            roadStatus: status == RouteStatus.warning
                ? RoadStatus.passable
                : RoadStatus.notPassable,
            createdAt: DateTime.utc(2026, 9, 23),
          ),
        ];
      }
      await tester.pumpWidget(
        _testApp(
          isGuest: false,
          routeService: routes,
          floodReportService: reports,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<RouteCard>(find.byType(RouteCard)).status, status);
      expect(find.text(status.label), findsOneWidget);
      await tester.tap(find.byType(RouteCard));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
            .status,
        status,
      );
      expect(find.text(status.label), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.text(status.label), findsOneWidget);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
            .status,
        status,
      );
      expect(find.text(status.label), findsOneWidget);
      expect(reports.fetchCalls, 1);
      expect(routes.fetchCalls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading, failure and retry remain unassessed until success', (
    tester,
  ) async {
    final pending = Completer<List<FloodReport>>();
    final reports = FakeFloodReportService()..onFetch = () => pending.future;
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: FakeRouteService()..routes = [exampleRoute()],
        floodReportService: reports,
      ),
    );
    await tester.pump();
    expect(tester.widget<RouteCard>(find.byType(RouteCard)).status, isNull);
    expect(find.text('SAFE'), findsNothing);
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Status not assessed'), findsOneWidget);
    await tester.tap(find.text('View'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen)).status,
      isNull,
    );
    pending.completeError(Exception('fetch failed'));
    await tester.pumpAndSettle();
    expect(find.text('Status not assessed'), findsOneWidget);
    expect(find.text('SAFE'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Status not assessed'), findsOneWidget);
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(tester.widget<RouteCard>(find.byType(RouteCard)).status, isNull);
    final retry = Completer<List<FloodReport>>();
    reports.onFetch = () => retry.future;
    await tester.ensureVisible(find.text('Retry flood reports'));
    await tester.tap(find.text('Retry flood reports'));
    await tester.pump();
    expect(find.text('SAFE'), findsNothing);
    retry.complete([]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RouteCard>(find.byType(RouteCard)).status,
      RouteStatus.clear,
    );
  });

  testWidgets(
    'report refresh recalculates Home but open Details keeps its snapshot',
    (tester) async {
      final reports = FakeFloodReportService();
      await tester.pumpWidget(
        _testApp(
          isGuest: false,
          routeService: FakeRouteService()..routes = [exampleRoute()],
          floodReportService: reports,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SAFE'), findsOneWidget);
      final refresh = Completer<List<FloodReport>>();
      reports.onFetch = () => refresh.future;
      await tester.tap(find.byTooltip('Refresh flood reports'));
      await tester.pump();
      expect(tester.widget<RouteCard>(find.byType(RouteCard)).status, isNull);
      await tester.tap(find.byType(RouteCard));
      await tester.pump(const Duration(milliseconds: 400));
      refresh.complete([exampleFloodReport()]);
      await tester.pumpAndSettle();
      expect(find.text('Status not assessed'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RouteCard>(find.byType(RouteCard)).status,
        RouteStatus.notPassable,
      );
      await tester.tap(find.byType(RouteCard));
      await tester.pumpAndSettle();
      expect(find.text('NOT PASSABLE'), findsOneWidget);
    },
  );

  for (final index in [0, 1]) {
    testWidgets('List opens exact saved route $index and Back keeps Home', (
      tester,
    ) async {
      final service = FakeRouteService()
        ..routes = [
          exampleRoute(),
          exampleRoute(id: 'route-2', name: 'Work route'),
        ];
      await tester.pumpWidget(_testApp(isGuest: false, routeService: service));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RouteCard).at(index));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
            .route,
        same(service.routes[index]),
      );
      expect(find.text(service.routes[index].name), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Saved routes'), findsOneWidget);
      expect(find.byType(RouteDetailsScreen), findsNothing);
      expect(service.fetchCalls, 1);
      expect(service.saveCalls, 0);
    });
  }

  testWidgets('Map View opens its exact route and Back preserves Map', (
    tester,
  ) async {
    final service = FakeRouteService()
      ..routes = [
        exampleRoute(),
        exampleRoute(id: 'route-2', name: 'Work route'),
      ];
    await tester.pumpWidget(_testApp(isGuest: false, routeService: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen)).route,
      same(service.routes.first),
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(
      tester
          .widget<SegmentedButton<HomeView>>(
            find.byType(SegmentedButton<HomeView>),
          )
          .selected,
      {HomeView.map},
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(service.fetchCalls, 1);
    expect(service.saveCalls, 0);
  });

  testWidgets('bottom route card chooses the Map line and Details route', (
    tester,
  ) async {
    usePhoneSize(tester);
    final first = exampleRoute();
    final second = exampleRoute(
      id: 'route-2',
      name: 'Work route',
      startLatitude: 15.16,
      startLongitude: 120.6,
      destinationLatitude: 15.17,
      destinationLongitude: 120.61,
    );
    final service = FakeRouteService()..routes = [first, second];
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: service,
        floodReportService: FakeFloodReportService()
          ..reports = [exampleFloodReport()],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    final picker = find.byKey(const Key('map-route-chooser'));
    expect(
      tester.widget<PopupMenuButton<String>>(picker).initialValue,
      first.id,
    );
    expect(find.text('NOT PASSABLE'), findsOneWidget);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.byType(CheckedPopupMenuItem<String>), findsNWidgets(2));
    expect(
      tester.getRect(find.byType(CheckedPopupMenuItem<String>).last).bottom,
      lessThanOrEqualTo(
        tester
            .getRect(find.byKey(const Key('selected-route-warning-card')))
            .top,
      ),
    );
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Work route'),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<PopupMenuButton<String>>(picker).initialValue,
      second.id,
    );
    expect(find.text('SAFE'), findsOneWidget);
    expect(find.text('NOT PASSABLE'), findsNothing);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(CheckedPopupMenuItem<String>).last).bottom,
      lessThanOrEqualTo(
        tester
            .getRect(find.byKey(const Key('selected-route-warning-card')))
            .top,
      ),
    );
    await tester.tapAt(const Offset(8, 300));
    await tester.pumpAndSettle();
    final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(line.polylines.single.points.first.latitude, second.startLatitude);
    expect(line.polylines.single.points.first.longitude, second.startLongitude);
    expect(
      line.polylines.single.points.last.latitude,
      second.destinationLatitude,
    );
    expect(
      line.polylines.single.points.last.longitude,
      second.destinationLongitude,
    );
    final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
    expect(
      camera.visibleBounds.contains(line.polylines.single.points.first),
      isTrue,
    );
    expect(
      camera.visibleBounds.contains(line.polylines.single.points.last),
      isTrue,
    );

    await tester.tap(find.byTooltip('Refresh flood reports'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PopupMenuButton<String>>(picker).initialValue,
      second.id,
    );

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckedPopupMenuItem<String>), findsNothing);
    expect(
      tester
          .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
          .route
          .id,
      second.id,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PopupMenuButton<String>>(picker).initialValue,
      second.id,
    );
  });

  testWidgets('deleting the selected Map route falls back to another route', (
    tester,
  ) async {
    usePhoneSize(tester);
    final first = exampleRoute();
    final second = exampleRoute(id: 'route-2', name: 'Work route');
    final service = FakeRouteService()..routes = [first, second];
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: service,
        floodReportService: FakeFloodReportService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-route-chooser')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Work route'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit or delete route'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete route'));
    await tester.tap(find.text('Delete route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.routes.map((route) => route.id), [first.id]);
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(find.byKey(const Key('map-route-chooser')), findsNothing);
    expect(find.text(first.name), findsOneWidget);
    final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(line.polylines.single.points.first.latitude, first.startLatitude);
    expect(line.polylines.single.points.first.longitude, first.startLongitude);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing Map route endpoints reframes the map', (tester) async {
    usePhoneSize(tester);
    final service = FakeRouteService()..routes = [exampleRoute()];
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: service,
        floodReportService: FakeFloodReportService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    final originalMapKey = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .key;
    final originalDestination = service.routes.single.destinationLatitude;

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit or delete route'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Destination'),
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Destination'));
    final editorMap = find.byKey(const Key('add-route-map'));
    await tester.ensureVisible(editorMap);
    await tester.tapAt(tester.getCenter(editorMap) + const Offset(50, 30));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(service.updateCalls, 1);
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
    final updatedRoute = service.routes.single;
    expect(updatedRoute.destinationLatitude, isNot(originalDestination));
    expect(
      tester.widget<FlutterMap>(find.byType(FlutterMap)).key,
      isNot(originalMapKey),
    );
    final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(
      line.polylines.single.points.last.latitude,
      updatedRoute.destinationLatitude,
    );
    final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
    expect(
      camera.visibleBounds.contains(line.polylines.single.points.last),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('bottom route chooser fits at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeRouteService()
        ..routes = [
          exampleRoute(),
          exampleRoute(id: 'route-2', name: 'Work route'),
        ];
      await tester.pumpWidget(
        _testApp(
          isGuest: false,
          routeService: service,
          floodReportService: FakeFloodReportService(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      final picker = find.byKey(const Key('map-route-chooser'));
      final card = find.byKey(const Key('selected-route-warning-card'));
      expect(picker, findsOneWidget);
      expect(
        tester.getRect(picker).left,
        greaterThanOrEqualTo(tester.getRect(card).left),
      );
      expect(
        tester.getRect(picker).right,
        lessThanOrEqualTo(tester.getRect(card).right),
      );
      if (width >= 800) {
        // PC layout: both panels are 360 px wide and share the left inset.
        final cardRect = tester.getRect(card);
        expect(cardRect.width, closeTo(360, 0.01));
        expect(cardRect.left, closeTo(24, 0.01));
        expect(find.text('No flood reports yet.'), findsOneWidget);
        final banner = find
            .ancestor(
              of: find.text('No flood reports yet.'),
              matching: find.byType(Material),
            )
            .first;
        final bannerRect = tester.getRect(banner);
        expect(bannerRect.width, closeTo(360, 0.01));
        expect(bannerRect.left, closeTo(cardRect.left, 0.01));
      }
      await tester.tap(picker);
      await tester.pumpAndSettle();
      expect(find.byType(CheckedPopupMenuItem<String>), findsNWidgets(2));
      expect(
        tester.getRect(find.byType(CheckedPopupMenuItem<String>).last).bottom,
        lessThanOrEqualTo(tester.getRect(card).top),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in {799.0: false, 800.0: true}.entries) {
    testWidgets('map uses the PC layout only from 800 px (${entry.key})', (
      tester,
    ) async {
      tester.view.physicalSize = Size(entry.key, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeRouteService()..routes = [exampleRoute()];
      await tester.pumpWidget(
        _testApp(
          isGuest: false,
          routeService: service,
          floodReportService: FakeFloodReportService(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('selected-route-warning-card'));
      // Phone layout spans the width minus 24 px on each side.
      expect(
        tester.getRect(card).width,
        closeTo(entry.value ? 360 : entry.key - 48, 0.01),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('map at 810 x 375 keeps panels, route and actions usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(810, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final routes = [
      for (var index = 1; index <= 8; index++)
        exampleRoute(id: 'route-$index', name: 'Route $index'),
    ];
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: FakeRouteService()..routes = routes,
        floodReportService: FakeFloodReportService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const Key('selected-route-warning-card')),
    );
    final bannerRect = tester.getRect(
      find
          .ancestor(
            of: find.text('No flood reports yet.'),
            matching: find.byType(Material),
          )
          .first,
    );
    final fabRect = tester.getRect(find.byType(FloatingActionButton));
    expect(cardRect.width, closeTo(360, 0.01));
    expect(bannerRect.width, closeTo(360, 0.01));
    expect(bannerRect.bottom, lessThan(cardRect.top));
    expect(cardRect.bottom, lessThanOrEqualTo(375));
    expect(fabRect.overlaps(cardRect), isFalse);
    expect(fabRect.right, lessThanOrEqualTo(810));
    expect(fabRect.bottom, lessThanOrEqualTo(375));

    // The framed route stays in the open map area, clear of panels and FAB.
    for (final key in const [
      'route-start-marker',
      'route-destination-marker',
    ]) {
      final marker = find.byKey(Key(key));
      expect(marker, findsOneWidget);
      final rect = tester.getRect(marker);
      expect(rect.left, greaterThanOrEqualTo(cardRect.right));
      expect(rect.overlaps(fabRect), isFalse);
    }

    // The chooser opens above the card, stays on-screen and scrolls.
    await tester.tap(find.byKey(const Key('map-route-chooser')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckedPopupMenuItem<String>), findsNWidgets(8));
    final menuRect = tester.getRect(
      find
          .ancestor(
            of: find.byType(CheckedPopupMenuItem<String>).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(menuRect.top, greaterThanOrEqualTo(0));
    expect(menuRect.bottom, lessThanOrEqualTo(cardRect.top));
    expect(menuRect.height, lessThan(8 * 48.0));
    final last = find.widgetWithText(CheckedPopupMenuItem<String>, 'Route 8');
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(const Key('map-route-chooser')),
          )
          .initialValue,
      'route-8',
    );

    // "View" stays reachable and opens the selected route.
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    final details = tester.widget<RouteDetailsScreen>(
      find.byType(RouteDetailsScreen),
    );
    expect(details.route.id, 'route-8');
    expect(tester.takeException(), isNull);
  });

  testWidgets('list at 810 x 375 keeps cards readable and actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(810, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeRouteService()
      ..routes = [
        exampleRoute(),
        exampleRoute(id: 'route-2', name: 'Work route'),
      ];
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: service,
        floodReportService: FakeFloodReportService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RouteCard), findsNWidgets(2));
    for (final element in find.byType(RouteCard).evaluate()) {
      final rect = tester.getRect(find.byElementPredicate((e) => e == element));
      expect(rect.width, lessThanOrEqualTo(720.01));
      expect(rect.left, greaterThanOrEqualTo(45 - 0.01));
    }
    final addRoute = tester.getRect(find.text('Add route'));
    expect(addRoute.top, greaterThanOrEqualTo(0));
    expect(addRoute.bottom, lessThanOrEqualTo(375));

    // The end of the list scrolls clear of the Report Flood button.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    final fabRect = tester.getRect(find.byType(FloatingActionButton));
    expect(
      tester.getRect(find.text('No flood reports yet.')).bottom,
      lessThanOrEqualTo(fabRect.top),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom route chooser scrolls through all saved routes', (
    tester,
  ) async {
    usePhoneSize(tester);
    final routes = [
      for (var index = 1; index <= 8; index++)
        exampleRoute(id: 'route-$index', name: 'Route $index'),
    ];
    final service = FakeRouteService()..routes = routes;
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: service,
        floodReportService: FakeFloodReportService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('map-route-chooser')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckedPopupMenuItem<String>), findsNWidgets(8));
    final card = find.byKey(const Key('selected-route-warning-card'));
    expect(
      tester.getRect(find.byType(CheckedPopupMenuItem<String>).first).top,
      lessThan(tester.getRect(card).top),
    );
    final last = find.widgetWithText(CheckedPopupMenuItem<String>, 'Route 8');
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(const Key('map-route-chooser')),
          )
          .initialValue,
      routes.last.id,
    );
    expect(find.text('Route 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest demo List and Map do not open private Details', (
    tester,
  ) async {
    final service = FakeRouteService();
    await tester.pumpWidget(_testApp(isGuest: true, routeService: service));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RouteCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(
      find.text(
        'This is a demo route. Sign in and save your own route to view its details.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byType(RouteDetailsScreen), findsNothing);
    expect(service.fetchCalls, 0);
    expect(service.saveCalls, 0);
  });

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
    expect(
      tester.widget<RouteCard>(find.byType(RouteCard).first).status,
      RouteStatus.warning,
    );
    expect(
      tester.widget<RouteCard>(find.byType(RouteCard).last).status,
      RouteStatus.clear,
    );
  });

  testWidgets('List and Map segments change one Home screen state', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isGuest: false));

    await tester.tap(find.text('Map'));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<HomeView>>(
            find.byType(SegmentedButton<HomeView>),
          )
          .selected,
      {HomeView.map},
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved routes'), findsNothing);
    final selector = tester.widget<SegmentedButton<HomeView>>(
      find.byType(SegmentedButton<HomeView>),
    );
    expect(
      selector.style!.backgroundColor!.resolve({}),
      AppColors.scaffoldBackground,
    );
    expect(selector.style!.foregroundColor!.resolve({}), AppColors.ink);
    expect(
      selector.style!.backgroundColor!.resolve({WidgetState.selected}),
      AppColors.warning,
    );

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();

    expect(find.text('Saved routes'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('rapid view switches keep only the selected view interactive', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isGuest: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Map'));
    await tester.pump();

    final selector = find.byType(SegmentedButton<HomeView>);
    expect(tester.widget<SegmentedButton<HomeView>>(selector).selected, {
      HomeView.map,
    });
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Saved routes'), findsOneWidget);
    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.text('Saved routes'),
              matching: find.byType(IgnorePointer),
            ),
          )
          .any((widget) => widget.ignoring),
      isTrue,
    );

    await tester.tap(find.text('List'));
    await tester.pump();

    expect(tester.widget<SegmentedButton<HomeView>>(selector).selected, {
      HomeView.list,
    });
    await tester.pumpAndSettle();
    expect(find.text('Saved routes'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
    expect(tester.takeException(), isNull);
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
    await tester.pumpAndSettle();

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
      expect(find.text('NOT PASSABLE'), findsOneWidget);
      expect(find.text('SAFE'), findsNothing);
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
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
      expect(find.text('NOT PASSABLE'), findsOneWidget);
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
      expect(find.text('SAFE'), findsOneWidget);
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
      expect(find.text('NOT PASSABLE'), findsOneWidget);
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
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
      expect(find.text('NOT PASSABLE'), findsOneWidget);
      expect(find.text('SAFE'), findsNothing);
      expect(find.text('WARNING'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Back waits for a pending report, then Home refreshes once', (
    tester,
  ) async {
    usePhoneSize(tester);
    final pending = Completer<void>();
    final reports = FakeFloodReportService()..onSubmit = () => pending.future;
    final routes = FakeRouteService()..routes = [exampleRoute()];
    await tester.pumpWidget(
      _testApp(
        isGuest: false,
        routeService: routes,
        floodReportService: reports,
      ),
    );
    await tester.pumpAndSettle();
    expect(reports.fetchCalls, 1);
    await tester.tap(find.text('Report Flood'));
    await tester.pumpAndSettle();
    await fillFloodForm(tester, notes: 'Pending crossing report');
    await submitFloodForm(tester);
    expect(reports.submitCalls, 1);

    await tester.pageBack();
    await tester.pump();
    expect(find.byType(ReportFloodScreen), findsOneWidget);
    expect(reports.fetchCalls, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ReportFloodScreen), findsNothing);
    expect(reports.submitCalls, 1);
    expect(reports.fetchCalls, 2);
    expect(find.text('Pending crossing report'), findsOneWidget);
    expect(find.text('NOT PASSABLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
