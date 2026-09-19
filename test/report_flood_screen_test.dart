import 'dart:async';

import 'package:bahantabay/core/theme/app_theme.dart';
import 'package:bahantabay/features/flood_reports/data/flood_report_service.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_depth.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';
import 'package:bahantabay/features/flood_reports/presentation/screens/report_flood_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_flood_report_service.dart';
import 'support/flood_form_actions.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    FakeFloodReportService service, {
    String? userId = 'user-a',
  }) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReportFloodScreen(service: service, userId: userId),
      ),
    );
  }

  testWidgets(
    'requires location, depth and road status, with optional public notes',
    (tester) async {
      final service = FakeFloodReportService();
      await open(tester, service);
      expect(find.text('Report location'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
      expect(find.textContaining('Notes are public.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await submitFloodForm(tester);
      // Errors may be outside the scroll viewport; scroll to each relevant field.
      await tester.ensureVisible(find.byKey(const Key('report-flood-map')));
      expect(find.text('Select a flood location on the map.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('flood-depth')));
      expect(find.text('Select a flood depth.'), findsOneWidget);
      await tester.ensureVisible(find.text('Road status'));
      expect(find.text('Select a road status.'), findsOneWidget);
      expect(service.submitCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading prevents duplicates and failed submit preserves all fields',
    (tester) async {
      final pending = Completer<void>();
      final service = FakeFloodReportService()..onSubmit = () => pending.future;
      await open(tester, service);
      await fillFloodForm(tester, notes: 'Water covers the crossing.');
      expect(find.byKey(const Key('selected-flood-location')), findsOneWidget);
      await submitFloodForm(tester);
      expect(service.submitCalls, 1);
      expect(service.lastUserId, 'user-a');
      expect(service.lastDraft!.depth, FloodDepth.knee);
      expect(service.lastDraft!.roadStatus, RoadStatus.notPassable);
      expect(service.lastDraft!.latitude, closeTo(15.1454, 0.01));
      expect(service.lastDraft!.notes, 'Water covers the crossing.');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(FilledButton));
      expect(service.submitCalls, 1);
      pending.completeError(
        const FloodReportFailure('Unable to submit. Please retry.'),
      );
      await tester.pump();
      expect(find.text('Unable to submit. Please retry.'), findsOneWidget);
      expect(find.byType(ReportFloodScreen), findsOneWidget);
      expect(find.text('Water covers the crossing.'), findsOneWidget);
      await tester.ensureVisible(find.text('Road status'));
      expect(
        tester
            .widget<SegmentedButton<RoadStatus>>(
              find.byType(SegmentedButton<RoadStatus>),
            )
            .selected,
        {RoadStatus.notPassable},
      );
      await tester.ensureVisible(find.byKey(const Key('flood-depth')));
      expect(find.text('Knee'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('report-flood-map')));
      expect(find.byKey(const Key('selected-flood-location')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('guest is blocked before entering a report', (tester) async {
    final service = FakeFloodReportService();
    await open(tester, service, userId: null);
    expect(find.text('Sign in to report a flood.'), findsOneWidget);
    expect(find.byKey(const Key('report-flood-map')), findsNothing);
    expect(find.text('Submit Report'), findsNothing);
    expect(service.submitCalls, 0);
  });
}
