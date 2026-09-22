import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/saved_route.dart';

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key, required this.route});

  final SavedRoute route;

  @override
  Widget build(BuildContext context) {
    final startPoint = LatLng(route.startLatitude, route.startLongitude);
    final destinationPoint = LatLng(
      route.destinationLatitude,
      route.destinationLongitude,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Route Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                _buildMap(startPoint, destinationPoint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(LatLng startPoint, LatLng destinationPoint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
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
