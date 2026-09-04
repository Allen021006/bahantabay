import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum RoadStatus { passable, notPassable }

extension RoadStatusStyle on RoadStatus {
  String get label {
    switch (this) {
      case RoadStatus.passable:
        return 'Passable';
      case RoadStatus.notPassable:
        return 'Not passable';
    }
  }

  Color get color {
    switch (this) {
      case RoadStatus.passable:
        return AppColors.mutedText;
      case RoadStatus.notPassable:
        return AppColors.errorText;
    }
  }
}
