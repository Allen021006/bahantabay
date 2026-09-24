import 'dart:math' as math;

import '../../flood_reports/domain/flood_report.dart';
import '../../flood_reports/domain/road_status.dart';
import 'route_status.dart';
import 'saved_route.dart';

class RouteStatusCalculator {
  static const double proximityThresholdMeters = 200.0;
  static const double metersPerDegreeLatitude = 111320.0;

  RouteStatus calculate({
    required SavedRoute route,
    required List<FloodReport> reports,
  }) {
    final referenceLatitude =
        (route.startLatitude + route.destinationLatitude) / 2;

    final longitudeMetersPerDegree =
        metersPerDegreeLatitude * math.cos(referenceLatitude * math.pi / 180);

    (double, double) toLocalMeters(double latitude, double longitude) {
      final x = (longitude - route.startLongitude) * longitudeMetersPerDegree;
      final y = (latitude - route.startLatitude) * metersPerDegreeLatitude;

      return (x, y);
    }

    final start = toLocalMeters(route.startLatitude, route.startLongitude);

    final end = toLocalMeters(
      route.destinationLatitude,
      route.destinationLongitude,
    );

    var hasWarning = false;

    for (final report in reports) {
      final point = toLocalMeters(report.latitude, report.longitude);

      final distance = _distanceToSegment(point: point, start: start, end: end);

      if (distance <= proximityThresholdMeters) {
        if (report.roadStatus == RoadStatus.notPassable) {
          return RouteStatus.notPassable;
        }

        if (report.roadStatus == RoadStatus.passable) {
          hasWarning = true;
        }
      }
    }

    return hasWarning ? RouteStatus.warning : RouteStatus.clear;
  }

  double _distanceToSegment({
    required (double, double) point,
    required (double, double) start,
    required (double, double) end,
  }) {
    final px = point.$1;
    final py = point.$2;

    final ax = start.$1;
    final ay = start.$2;

    final bx = end.$1;
    final by = end.$2;

    final abX = bx - ax;
    final abY = by - ay;

    final apX = px - ax;
    final apY = py - ay;

    final segmentLengthSquared = (abX * abX) + (abY * abY);

    if (segmentLengthSquared == 0) {
      return math.sqrt((apX * apX) + (apY * apY));
    }

    final projection = ((apX * abX) + (apY * abY)) / segmentLengthSquared;

    final t = projection.clamp(0.0, 1.0);

    final closestX = ax + (t * abX);
    final closestY = ay + (t * abY);

    final distanceX = px - closestX;
    final distanceY = py - closestY;

    return math.sqrt((distanceX * distanceX) + (distanceY * distanceY));
  }
}
