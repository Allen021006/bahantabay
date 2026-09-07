import 'package:flutter/material.dart';
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
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: HomeScreen(
      isGuest: isGuest,
      email: email,
      showDemoData: showDemoData,
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

  testWidgets('signed-in Home shell renders demo routes and reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(isGuest: false, email: 'commuter@example.com'),
    );

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
    await tester.pumpWidget(_testApp(isGuest: true));

    final addRoute = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Add route'),
    );
    final reportFlood = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );

    expect(addRoute.onPressed, isNull);
    expect(reportFlood.onPressed, isNull);
    expect(find.byType(RouteCard), findsNWidgets(2));
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

    await tester.pumpWidget(_testApp(isGuest: false));
    await tester.tap(find.text('Map'));
    await tester.pump();

    expect(find.byKey(const Key('home-map')), findsOneWidget);
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

    expect(find.text('No saved routes yet.'), findsOneWidget);
    expect(find.text('No nearby flood reports.'), findsOneWidget);
    expect(find.byType(RouteCard), findsNothing);
    expect(find.byType(FloodReportEntry), findsNothing);
  });
}
