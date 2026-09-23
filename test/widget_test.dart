// A widget test: it builds your app in memory and checks what is on screen.
// Run them all with: flutter test
//
// You are not required to write more of these, but a project with a few real
// tests reads very differently from one with none.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/app/bahantabay_app.dart';
import 'package:bahantabay/core/theme/app_colors.dart';
import 'package:bahantabay/features/splash/presentation/screens/splash_screen.dart';
import 'auth_gate_test.dart' show FakeAuthService;
import 'support/fake_route_service.dart';
import 'support/fake_flood_report_service.dart';

void main() {
  testWidgets('app shows splash then opens Sign In and Guest Entry screen', (
    tester,
  ) async {
    await tester.pumpWidget(const BahantabayApp());

    // The splash should be present when the app first starts.
    expect(find.text('BAHANTABAY'), findsOneWidget);

    // Allow the complete splash animation and crossfade to finish.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // After startup, the normal authentication entry screen should be
    // available.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Bahantabay'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('splash blocks keyboard focus until the crossfade finishes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const BahantabayApp());
    expect(find.bySemanticsLabel('Continue as Guest'), findsNothing);
    final field = tester.widget<EditableText>(find.byType(EditableText).first);
    field.focusNode.requestFocus();
    await tester.pump();
    expect(field.focusNode.hasFocus, isFalse);
    await tester.pump(const Duration(milliseconds: 3200));
    field.focusNode.requestFocus();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(field.focusNode.hasFocus, isFalse);
    await tester.pumpAndSettle();
    field.focusNode.requestFocus();
    await tester.pump();
    expect(field.focusNode.hasFocus, isTrue);
    expect(find.bySemanticsLabel('Continue as Guest'), findsOneWidget);
    semantics.dispose();
  });

  for (final elapsed in [1000, 3400]) {
    testWidgets('disposing splash at ${elapsed}ms is safe', (tester) async {
      await tester.pumpWidget(const BahantabayApp());
      if (elapsed > 3200) {
        await tester.pump(const Duration(milliseconds: 3200));
        await tester.pump(Duration(milliseconds: elapsed - 3200));
      } else {
        await tester.pump(Duration(milliseconds: elapsed));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('fresh launch shows splash and restores authenticated Home', (
    tester,
  ) async {
    final auth = FakeAuthService(
      hasActiveSession: true,
      currentUserEmail: 'a@example.com',
    );
    addTearDown(auth.dispose);
    for (var launch = 0; launch < 2; launch++) {
      await tester.pumpWidget(
        BahantabayApp(
          authService: auth,
          routeService: FakeRouteService(),
          floodReportService: FakeFloodReportService(),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Saved routes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('app uses the approved Bahantabay theme', (tester) async {
    await tester.pumpWidget(const BahantabayApp());

    // Inspect the ThemeData configured directly on the app's MaterialApp.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = app.theme!;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.floodBlue);
    expect(theme.scaffoldBackgroundColor, AppColors.scaffoldBackground);
    expect(theme.colorScheme.error, AppColors.floodRed);
  });
}
