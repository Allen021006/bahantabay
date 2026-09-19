import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/features/authentication/data/auth_service.dart';
import 'package:bahantabay/features/authentication/presentation/auth_gate.dart';
import 'package:bahantabay/features/routes/data/route_service.dart';
import 'support/fake_route_service.dart';
import 'support/fake_flood_report_service.dart';
import 'package:bahantabay/features/flood_reports/data/flood_report_service.dart';
import 'package:bahantabay/features/flood_reports/presentation/screens/report_flood_screen.dart';
import 'package:bahantabay/features/flood_reports/presentation/widgets/flood_report_entry.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.hasActiveSession = false, this.currentUserEmail});

  final _sessionController = StreamController<AuthSessionSnapshot>.broadcast();

  @override
  bool hasActiveSession;

  @override
  String? currentUserEmail;

  @override
  String? get currentUserId => hasActiveSession ? currentUserEmail : null;

  void changeAccount(String? email) {
    currentUserEmail = email;
    hasActiveSession = email != null;
    _sessionController.add(
      AuthSessionSnapshot(
        isSignedIn: hasActiveSession,
        email: email,
        userId: currentUserId,
      ),
    );
  }

  int signOutCalls = 0;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => _sessionController.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    hasActiveSession = true;
    currentUserEmail = email;
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    hasActiveSession = true;
    currentUserEmail = email;
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    hasActiveSession = false;
    currentUserEmail = null;
  }

  Future<void> dispose() => _sessionController.close();
}

Widget _testApp(
  AuthService? service, {
  RouteService? routes,
  FloodReportService? reports,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: AuthGate(
      authService: service,
      routeService: routes,
      floodReportService: reports,
    ),
  );
}

void main() {
  testWidgets(
    'account change discards report draft while public reports remain readable',
    (tester) async {
      final auth = FakeAuthService(
        hasActiveSession: true,
        currentUserEmail: 'a@example.com',
      );
      addTearDown(auth.dispose);
      final reports = FakeFloodReportService()
        ..reports = [exampleFloodReport()];
      final routes = FakeRouteService()
        ..routes = [
          exampleRoute(userId: 'a@example.com', name: 'A private route'),
          exampleRoute(userId: 'b@example.com', name: 'B private route'),
        ];
      await tester.pumpWidget(_testApp(auth, routes: routes, reports: reports));
      await tester.pumpAndSettle();
      expect(find.text('A private route'), findsOneWidget);
      await tester.tap(find.text('Report Flood'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportFloodScreen), findsOneWidget);
      auth.changeAccount('b@example.com');
      await tester.pumpAndSettle();
      expect(find.byType(ReportFloodScreen), findsNothing);
      expect(find.text('A private route'), findsNothing);
      expect(find.text('B private route'), findsOneWidget);
      expect(find.byType(FloodReportEntry), findsOneWidget);
      auth.changeAccount(null);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue as Guest'));
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      expect(find.text('B private route'), findsNothing);
      expect(find.byType(FloodReportEntry), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      expect(reports.submitCalls, 0);
    },
  );
  testWidgets('account change discards open draft and stale route response', (
    tester,
  ) async {
    final auth = FakeAuthService(
      hasActiveSession: true,
      currentUserEmail: 'a@example.com',
    );
    addTearDown(auth.dispose);
    final pending = Completer<List<Never>>();
    final routes = FakeRouteService()
      ..routes = [
        exampleRoute(userId: 'b@example.com', name: 'B private route'),
      ];
    routes.onFetch = (id) async =>
        id == 'a@example.com' ? await pending.future : routes.routes;
    await tester.pumpWidget(_testApp(auth, routes: routes));
    await tester.tap(find.text('Add route'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Route name'), findsOneWidget);
    auth.changeAccount('b@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Route name'), findsNothing);
    expect(find.text('B private route'), findsOneWidget);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('B private route'), findsOneWidget);
    auth.changeAccount(null);
    await tester.pumpAndSettle();
    expect(find.text('B private route'), findsNothing);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
  testWidgets('restores an existing authenticated session', (tester) async {
    final service = FakeAuthService(
      hasActiveSession: true,
      currentUserEmail: 'commuter@example.com',
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(_testApp(service));

    expect(find.text('Saved routes'), findsOneWidget);
    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    expect(find.text('commuter@example.com'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('signs in and signs out through the auth gate', (tester) async {
    final service = FakeAuthService();
    addTearDown(service.dispose);
    await tester.pumpWidget(_testApp(service));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email'),
      'commuter@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'password123',
    );
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.text('Saved routes'), findsOneWidget);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(service.signOutCalls, 1);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('guest mode works without Supabase configuration', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(null));

    await tester.ensureVisible(find.text('Continue as Guest'));
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Saved routes'), findsOneWidget);
    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    expect(find.text('Guest session'), findsOneWidget);
    expect(find.text('Sign in / Create account'), findsOneWidget);
  });
}
