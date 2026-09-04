import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum RouteStatus { clear, warning, notPassable }

extension RouteStatusStyle on RouteStatus {
  String get label {
    switch (this) {
      case RouteStatus.clear:
        return 'SAFE';
      case RouteStatus.warning:
        return 'WARNING';
      case RouteStatus.notPassable:
        return 'NOT PASSABLE';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RouteStatus.clear:
        return AppColors.safeBackground;
      case RouteStatus.warning:
        return AppColors.warningBackground;
      case RouteStatus.notPassable:
        return AppColors.notPassableBackground;
    }
  }

  Color get foregroundColor {
    switch (this) {
      case RouteStatus.clear:
        return AppColors.safeForeground;
      case RouteStatus.warning:
        return AppColors.warningForeground;
      case RouteStatus.notPassable:
        return AppColors.notPassableForeground;
    }
  }
}
