// A widget test: it builds your app in memory and checks what is on screen.
// Run them all with: flutter test
//
// You are not required to write more of these, but a project with a few real
// tests reads very differently from one with none.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/app/bahantabay_app.dart';
import 'package:bahantabay/core/theme/app_colors.dart';

void main() {
  testWidgets('app opens the Sign In and Guest Entry screen', (tester) async {
    await tester.pumpWidget(const BahantabayApp());

    expect(find.text('Bahantabay'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('app uses the approved Bahantabay theme', (tester) async {
    await tester.pumpWidget(const BahantabayApp());

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.floodBlue);
    expect(theme.scaffoldBackgroundColor, AppColors.scaffoldBackground);
    expect(theme.colorScheme.error, AppColors.floodRed);
  });
}
