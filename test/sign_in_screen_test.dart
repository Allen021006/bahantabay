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

  testWidgets(
    'password visibility toggles with crossfade and preserves the value',
    (tester) async {
      await tester.pumpWidget(_testApp());

      final passwordField = find.byType(TextFormField).at(1);
      final passwordEditor = find.byType(EditableText).at(1);

      await tester.enterText(passwordField, 'secret123');

      expect(tester.widget<EditableText>(passwordEditor).obscureText, isTrue);
      expect(
        tester.widget<EditableText>(passwordEditor).controller.text,
        'secret123',
      );
      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(find.byTooltip('Hide password'), findsNothing);

      // Toggle to visible.
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      // Visibility and tooltip change immediately.
      expect(tester.widget<EditableText>(passwordEditor).obscureText, isFalse);
      expect(
        tester.widget<EditableText>(passwordEditor).controller.text,
        'secret123',
      );
      expect(find.byTooltip('Hide password'), findsOneWidget);

      await tester.pump();

      // Finish the 150 ms crossfade.
      await tester.pump(const Duration(milliseconds: 150));
      // Advance past the completion boundary to remove the outgoing icon.
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Toggle back to hidden.
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();

      // Visibility and tooltip change immediately again.
      expect(tester.widget<EditableText>(passwordEditor).obscureText, isTrue);
      expect(
        tester.widget<EditableText>(passwordEditor).controller.text,
        'secret123',
      );
      expect(find.byTooltip('Show password'), findsOneWidget);

      await tester.pump();
      // Finish the reverse 150 ms crossfade.
      await tester.pump(const Duration(milliseconds: 150));
      // Advance past the completion boundary to remove the outgoing icon.
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    },
  );

  testWidgets(
    'password visibility skips animation when animations are disabled',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SignInScreen(
              onSignIn: (_, _) async => null,
              onSignUp: (_, _) async => null,
              onContinueAsGuest: () {},
            ),
          ),
        ),
      );

      final passwordField = find.byType(TextFormField).at(1);
      final passwordEditor = find.byType(EditableText).at(1);

      await tester.enterText(passwordField, 'secret123');

      expect(tester.widget<EditableText>(passwordEditor).obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      // With animations disabled, the visibility change is immediate.
      expect(tester.widget<EditableText>(passwordEditor).obscureText, isFalse);
      expect(
        tester.widget<EditableText>(passwordEditor).controller.text,
        'secret123',
      );
      expect(find.byTooltip('Hide password'), findsOneWidget);

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    },
  );
}
