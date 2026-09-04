import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/core/widgets/primary_button.dart';
import 'package:bahantabay/features/authentication/presentation/screens/sign_in_screen.dart';

Widget _testApp() {
  return MaterialApp(
    theme: AppTheme.light,
    home: SignInScreen(
      onSignIn: (_, _) async => null,
      onSignUp: (_, _) async => null,
      onContinueAsGuest: () {},
    ),
  );
}

void main() {
  testWidgets('Sign In mode renders the approved actions and fields', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Bahantabay'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Sign In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.widgetWithText(TextFormField, 'Enter your email'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Enter your password'),
      findsOneWidget,
    );
  });

  testWidgets('mode link switches the same screen to Sign Up', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Sign Up'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
