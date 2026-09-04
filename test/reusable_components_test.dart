import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/core/widgets/empty_state.dart';
import 'package:bahantabay/core/widgets/primary_button.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';
import 'package:bahantabay/features/flood_reports/presentation/widgets/flood_report_entry.dart';
import 'package:bahantabay/features/routes/domain/route_status.dart';
import 'package:bahantabay/features/routes/presentation/widgets/route_card.dart';
import 'package:bahantabay/features/routes/presentation/widgets/route_warning_banner.dart';
import 'package:bahantabay/features/routes/presentation/widgets/status_badge.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('status badges always show their status label', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const Column(
          children: [
            StatusBadge(status: RouteStatus.clear),
            StatusBadge(status: RouteStatus.warning),
            StatusBadge(status: RouteStatus.notPassable),
          ],
        ),
      ),
    );

    expect(find.text('SAFE'), findsOneWidget);
    expect(find.text('WARNING'), findsOneWidget);
    expect(find.text('NOT PASSABLE'), findsOneWidget);
  });

  testWidgets('route card shows route details and handles taps', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _testApp(
        RouteCard(
          routeName: 'School route',
          startLabel: 'Home',
          endLabel: 'University',
          status: RouteStatus.warning,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('School route'), findsOneWidget);
    expect(find.text('Home → University'), findsOneWidget);
    expect(find.text('WARNING'), findsOneWidget);

    await tester.tap(find.byType(RouteCard));
    expect(tapped, isTrue);
  });

  testWidgets('flood report entry shows its supplied report data', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        FloodReportEntry(
          location: 'Quezon Avenue',
          floodDepth: 'Knee-deep',
          roadStatus: RoadStatus.notPassable,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ),
    );

    expect(find.text('Quezon Avenue'), findsOneWidget);
    expect(find.textContaining('Knee-deep'), findsOneWidget);
    expect(find.textContaining('Not passable'), findsOneWidget);
    expect(find.text('10 min ago'), findsOneWidget);
  });

  testWidgets('loading primary button cannot be pressed', (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      _testApp(
        PrimaryButton(
          label: 'Save route',
          isLoading: true,
          onPressed: () => presses++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(presses, 0);
  });

  testWidgets('empty state and warning banner show their messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const Column(
          children: [
            EmptyState(message: 'No saved routes yet.', icon: Icons.route),
            RouteWarningBanner(
              message: 'This route has an active flood report nearby.',
            ),
          ],
        ),
      ),
    );

    expect(find.text('No saved routes yet.'), findsOneWidget);
    expect(find.byIcon(Icons.route), findsOneWidget);
    expect(
      find.text('This route has an active flood report nearby.'),
      findsOneWidget,
    );
  });
}
