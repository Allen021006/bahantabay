import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/route_service.dart';
import '../../domain/saved_route.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key, this.routeService, this.userId, this.route});
  final RouteService? routeService;
  final String? userId;
  final SavedRoute? route;

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
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    if (route != null) {
      _nameController.text = route.name;
      _start = LatLng(route.startLatitude, route.startLongitude);
      _destination = LatLng(
        route.destinationLatitude,
        route.destinationLongitude,
      );
      _startController.text =
          '${route.startLatitude.toStringAsFixed(5)}, ${route.startLongitude.toStringAsFixed(5)}';
      _destinationController.text =
          '${route.destinationLatitude.toStringAsFixed(5)}, ${route.destinationLongitude.toStringAsFixed(5)}';
    }
  }

  Future<void> _deleteRoute() async {
    if (_isSaving) return;
    final route = widget.route;
    final service = widget.routeService;
    final userId = widget.userId;
    if (route == null ||
        service == null ||
        userId == null ||
        route.userId != userId) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text(
          'Delete "${route.name}" from your saved routes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await service.deleteRoute(userId, route.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _saveError = error is RouteFailure
              ? error.message
              : 'Could not delete your route. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point) {
    if (_isSaving) return;
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

  Future<void> _saveRoute() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    final service = widget.routeService;
    final userId = widget.userId;
    if (service == null ||
        userId == null ||
        (widget.route != null && widget.route!.userId != userId)) {
      setState(() => _saveError = 'Sign in to save a route.');
      return;
    }
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final draft = RouteDraft(
        name: _nameController.text,
        startLatitude: _start!.latitude,
        startLongitude: _start!.longitude,
        destinationLatitude: _destination!.latitude,
        destinationLongitude: _destination!.longitude,
      );
      if (widget.route == null) {
        await service.saveRoute(userId, draft);
      } else {
        await service.updateRoute(userId, widget.route!.id, draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _saveError = error is RouteFailure
            ? error.message
            : 'Could not save your route. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.route == null ? 'Add route' : 'Edit route'),
        ),
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
                  enabled: !_isSaving,
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
                if (_saveError != null) ...[
                  Text(
                    _saveError!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.errorText),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                PrimaryButton(
                  label: widget.route == null ? 'Save route' : 'Save changes',
                  onPressed: _saveRoute,
                  isLoading: _isSaving,
                ),
                if (widget.route != null)
                  TextButton.icon(
                    onPressed: _isSaving ? null : _deleteRoute,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete route'),
                  ),
              ],
            ),
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
            initialCameraFit: _start == null || _destination == null
                ? null
                : CameraFit.bounds(
                    bounds: LatLngBounds(_start!, _destination!),
                    padding: const EdgeInsets.all(48),
                    maxZoom: 16,
                  ),
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
