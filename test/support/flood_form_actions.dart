import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> fillFloodForm(WidgetTester tester, {String? notes}) async {
  final map = find.byKey(const Key('report-flood-map'));
  await tester.ensureVisible(map);
  await tester.tapAt(tester.getCenter(map));
  await tester.pump(const Duration(milliseconds: 400));
  final depth = find.byKey(const Key('flood-depth'));
  await tester.ensureVisible(depth);
  await tester.tap(depth);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Knee').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Not passable'));
  await tester.tap(find.text('Not passable'));
  await tester.pump();
  if (notes != null) {
    final field = find.byKey(const Key('flood-notes'));
    await tester.ensureVisible(field);
    await tester.enterText(field, notes);
  }
}

Future<void> submitFloodForm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Submit Report'));
  await tester.tap(find.text('Submit Report'));
  await tester.pump();
}

void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
