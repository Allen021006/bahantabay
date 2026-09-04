import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/features/authentication/data/auth_service.dart';
import 'package:bahantabay/features/authentication/presentation/auth_gate.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.hasActiveSession = false, this.currentUserEmail});

  final _sessionController = StreamController<AuthSessionSnapshot>.broadcast();

  @override
  bool hasActiveSession;

  @override
  String? currentUserEmail;

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

Widget _testApp(AuthService? service) {
  return MaterialApp(
    theme: AppTheme.light,
    home: AuthGate(authService: service),
  );
}

void main() {
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
