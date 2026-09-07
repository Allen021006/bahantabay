import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _destinationController = TextEditingController();
  LatLng? _start;
  LatLng? _destination;
  bool _selectingStart = true;
  bool _showValidation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point) {
    setState(() {
      final coordinates =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      if (_selectingStart) {
        _start = point;
        _startController.text = coordinates;
        _selectingStart = false;
      } else {
        _destination = point;
        _destinationController.text = coordinates;
      }
    });
    if (_showValidation) _formKey.currentState!.validate();
  }

  void _saveRoute() {
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    // Phase 7 validates only. Keep the draft here until persistence is added.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Route preview is ready. Saving is not available yet.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add route')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidation
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Route name', 'e.g. Home to School'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a route name.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select route points',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildMap(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _selectingStart
                    ? 'Tap the map to select your starting point.'
                    : 'Tap the map to select your destination.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPointField(isStart: true),
              const SizedBox(height: AppSpacing.md),
              _buildPointField(isStart: false),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: 'Save route', onPressed: _saveRoute),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildPointField({required bool isStart}) {
    return TextFormField(
      controller: isStart ? _startController : _destinationController,
      readOnly: true,
      showCursor: false,
      onTap: () => setState(() => _selectingStart = isStart),
      decoration:
          _decoration(
            isStart ? 'Start location' : 'Destination',
            'Tap here, then select on the map',
          ).copyWith(
            prefixIcon: Icon(isStart ? Icons.trip_origin : Icons.flag_outlined),
          ),
      validator: (_) {
        if ((isStart ? _start : _destination) == null) {
          return isStart
              ? 'Select a starting point on the map.'
              : 'Select a destination on the map.';
        }
        if (!isStart && _start == _destination) {
          return 'Choose a destination different from the start.';
        }
        return null;
      },
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          key: const Key('add-route-map'),
          options: MapOptions(
            initialCenter: const LatLng(15.1454, 120.5922),
            initialZoom: 15.2,
            backgroundColor: AppColors.mapSurface,
            onTap: (_, point) => _selectPoint(point),
          ),
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.mapSurface.withValues(alpha: 0.6),
                BlendMode.srcATop,
              ),
              child: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahantabay.app',
              ),
            ),
            if (_start != null && _destination != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_start!, _destination!],
                    color: AppColors.floodBlue,
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: [12, 8]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_start != null) _pointMarker(_start!, 'Start'),
                if (_destination != null)
                  _pointMarker(_destination!, 'Destination'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          Icon(
            label == 'Start' ? Icons.trip_origin : Icons.flag,
            color: AppColors.floodBlue,
          ),
        ],
      ),
    );
  }
}
