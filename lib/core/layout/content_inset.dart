import 'dart:math' as math;

import '../theme/app_spacing.dart';

/// Keeps scrollable content centered on wide screens while retaining the
/// existing 24-pixel edge spacing on phones.
double centeredContentInset(
  double availableWidth, {
  required double maxContentWidth,
}) => math.max(AppSpacing.lg, (availableWidth - maxContentWidth) / 2);
