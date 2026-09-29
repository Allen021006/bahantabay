import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/layout/content_inset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/route_service.dart';
import 'add_route_screen.dart';
import '../../domain/saved_route.dart';
import '../../domain/route_status.dart';
import '../widgets/status_badge.dart';

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({
    super.key,
    required this.route,
    this.status,
    this.routeService,
    this.userId,
  });

  final SavedRoute route;
  final RouteStatus? status;
  final RouteService? routeService;
  final String? userId;

  static const _maxContentWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    final startPoint = LatLng(route.startLatitude, route.startLongitude);
    final destinationPoint = LatLng(
      route.destinationLatitude,
      route.destinationLongitude,
    );
    // Shrink on short viewports so there is room around the map to scroll.
    final mapHeight = (MediaQuery.sizeOf(context).height * 0.6)
        .clamp(200.0, 280.0)
        .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        actions: [
          if (routeService != null && userId == route.userId)
            IconButton(
              tooltip: 'Edit or delete route',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddRouteScreen(
                      route: route,
                      routeService: routeService,
                      userId: userId,
                    ),
                  ),
                );
                // Return Home so it reloads the route and reassesses its endpoints.
                if (context.mounted && changed == true) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, constraints) => SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: centeredContentInset(
                  constraints.maxWidth,
                  maxContentWidth: _maxContentWidth,
                ),
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Status', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  if (status != null)
                    StatusBadge(status: status!)
                  else
                    Text(
                      'Status not assessed',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('START', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${startPoint.latitude}, ${startPoint.longitude}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'DESTINATION',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${destinationPoint.latitude}, ${destinationPoint.longitude}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMap(mapHeight, startPoint, destinationPoint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(double height, LatLng startPoint, LatLng destinationPoint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds(startPoint, destinationPoint),
              padding: const EdgeInsets.all(48),
              maxZoom: 16,
            ),
            backgroundColor: AppColors.mapSurface,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bahantabay.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [startPoint, destinationPoint],
                  color: AppColors.floodBlue,
                  strokeWidth: 3,
                  pattern: StrokePattern.dashed(segments: [12, 8]),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                _pointMarker(startPoint, 'Start'),
                _pointMarker(destinationPoint, 'Destination'),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Marker _pointMarker(LatLng point, String label) {
    return Marker(
      point: point,
      width: 110,
      height: 56,
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Icon(
              label == 'Start' ? Icons.trip_origin : Icons.flag,
              color: AppColors.floodBlue,
            ),
          ],
        ),
      ),
    );
  }
}
