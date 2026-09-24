import 'package:flutter_test/flutter_test.dart';

import 'package:bahantabay/features/flood_reports/domain/flood_depth.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_report.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';
import 'package:bahantabay/features/routes/domain/route_status.dart';
import 'package:bahantabay/features/routes/domain/route_status_calculator.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';

void main() {
  final calculator = RouteStatusCalculator();

  test('returns SAFE when there are no flood reports', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: []);

    expect(result, RouteStatus.clear);
  });

  test('ignores a flood report beyond 200 meters from the route', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-1',
      latitude: 15.1430,
      longitude: 120.5900,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.notPassable,
      notes: 'Test report beyond route threshold.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.clear);
  });

  test('returns WARNING for a nearby passable flood report', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-warning',
      latitude: 15.1410,
      longitude: 120.5900,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.passable,
      notes: 'Flooding reported but road is still passable.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.warning);
  });

  test('returns NOT PASSABLE for a nearby not-passable flood report', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-not-passable',
      latitude: 15.1410,
      longitude: 120.5900,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.notPassable,
      notes: 'Flooding reported and road is not passable.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.notPassable);
  });

  test('uses the most severe status when multiple reports are nearby', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final warningReport = FloodReport(
      id: 'report-warning',
      latitude: 15.1410,
      longitude: 120.5900,
      depth: FloodDepth.ankle,
      roadStatus: RoadStatus.passable,
      notes: 'Road is still passable.',
      createdAt: DateTime(2026, 1, 1),
    );

    final notPassableReport = FloodReport(
      id: 'report-not-passable',
      latitude: 15.1410,
      longitude: 120.5900,
      depth: FloodDepth.waist,
      roadStatus: RoadStatus.notPassable,
      notes: 'Road is not passable.',
      createdAt: DateTime(2026, 1, 2),
    );

    final result = calculator.calculate(
      route: route,
      reports: [warningReport, notPassableReport],
    );

    expect(result, RouteStatus.notPassable);
  });

  test('detects a flood report near the middle of the route segment', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-middle',
      latitude: 15.1450,
      longitude: 120.5950,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.notPassable,
      notes: 'Flood report near the middle of the route.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.notPassable);
  });

  test('detects a flood report at the route start', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-start',
      latitude: 15.1400,
      longitude: 120.5900,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.passable,
      notes: 'Flood report at route start.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.warning);
  });

  test('detects a flood report at the route destination', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-destination',
      latitude: 15.1500,
      longitude: 120.6000,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.notPassable,
      notes: 'Flood report at route destination.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.notPassable);
  });

  test(
    'ignores a report beyond the route endpoint when farther than 200 meters',
    () {
      final route = SavedRoute(
        id: 'route-1',
        userId: 'user-1',
        name: 'Test Route',
        startLatitude: 15.1400,
        startLongitude: 120.5900,
        destinationLatitude: 15.1500,
        destinationLongitude: 120.6000,
        createdAt: DateTime(2026, 1, 1),
      );

      final report = FloodReport(
        id: 'report-past-destination',
        latitude: 15.1520,
        longitude: 120.6020,
        depth: FloodDepth.chest,
        roadStatus: RoadStatus.notPassable,
        notes: 'Report past the destination.',
        createdAt: DateTime(2026, 1, 1),
      );

      final result = calculator.calculate(route: route, reports: [report]);

      expect(result, RouteStatus.clear);
    },
  );

  test('includes a report exactly 200 meters from the route', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    const latitudeOffset = 200.0 / 111320.0;

    final report = FloodReport(
      id: 'report-exact-boundary',
      latitude: 15.1400 - latitudeOffset,
      longitude: 120.5900,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.passable,
      notes: 'Report exactly at the proximity boundary.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.warning);
  });

  test('ignores a report just beyond 200 meters from the route', () {
    final route = SavedRoute(
      id: 'route-1',
      userId: 'user-1',
      name: 'Test Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1500,
      destinationLongitude: 120.6000,
      createdAt: DateTime(2026, 1, 1),
    );

    const latitudeOffset = 201.0 / 111320.0;

    final report = FloodReport(
      id: 'report-outside-boundary',
      latitude: 15.1400 - latitudeOffset,
      longitude: 120.5900,
      depth: FloodDepth.chest,
      roadStatus: RoadStatus.notPassable,
      notes: 'Report just outside the proximity boundary.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: route, reports: [report]);

    expect(result, RouteStatus.clear);
  });

  test('handles a route with identical start and destination', () {
    final pointRoute = SavedRoute(
      id: 'point-route',
      userId: 'user-1',
      name: 'Point Route',
      startLatitude: 15.1400,
      startLongitude: 120.5900,
      destinationLatitude: 15.1400,
      destinationLongitude: 120.5900,
      createdAt: DateTime(2026, 1, 1),
    );

    final report = FloodReport(
      id: 'report-point-route',
      latitude: 15.1410,
      longitude: 120.5900,
      depth: FloodDepth.knee,
      roadStatus: RoadStatus.passable,
      notes: 'Nearby report for a zero-length route.',
      createdAt: DateTime(2026, 1, 1),
    );

    final result = calculator.calculate(route: pointRoute, reports: [report]);

    expect(result, RouteStatus.warning);
  });
}
