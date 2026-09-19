import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/flood_report_service.dart';
import '../../domain/flood_depth.dart';
import '../../domain/flood_report.dart';
import '../../domain/road_status.dart';

class ReportFloodScreen extends StatefulWidget {
  const ReportFloodScreen({super.key, this.service, this.userId});

  final FloodReportService? service;
  final String? userId;

  @override
  State<ReportFloodScreen> createState() => _ReportFloodScreenState();
}

class _ReportFloodScreenState extends State<ReportFloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  LatLng? _location;
  FloodDepth? _depth;
  RoadStatus? _roadStatus;
  bool _showValidation = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    final service = widget.service;
    final userId = widget.userId;
    if (service == null || userId == null) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await service.submitReport(
        userId,
        FloodReportDraft(
          latitude: _location!.latitude,
          longitude: _location!.longitude,
          depth: _depth!,
          roadStatus: _roadStatus!,
          notes: _notesController.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _submitError = error is FloodReportFailure
            ? error.message
            : 'Could not submit your report. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Flood')),
      body: SafeArea(
        child: widget.userId == null || widget.service == null
            ? EmptyState(
                message: widget.userId == null
                    ? 'Sign in to report a flood.'
                    : 'Reporting is unavailable. Please try again later.',
                icon: Icons.lock_outline,
              )
            : Form(
                key: _formKey,
                autovalidateMode: _showValidation
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heading('Report location'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildLocation(),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<FloodDepth>(
                        key: const Key('flood-depth'),
                        isExpanded: true,
                        decoration: _decoration('Flood depth'),
                        hint: const Text('Select flood depth'),
                        items: [
                          for (final depth in FloodDepth.values)
                            DropdownMenuItem(
                              value: depth,
                              child: Text(depth.label),
                            ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _depth = value),
                        validator: (value) =>
                            value == null ? 'Select a flood depth.' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _heading('Road status'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildRoadStatus(),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        key: const Key('flood-notes'),
                        controller: _notesController,
                        enabled: !_submitting,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: FloodReportDraft.maxNotesLength,
                        decoration: _decoration('Notes (optional)').copyWith(
                          hintText: 'Add details about the flood...',
                          helperText:
                              'Notes are public. Do not include names, phone numbers or other private details.',
                          helperMaxLines: 3,
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            (value?.length ?? 0) >
                                FloodReportDraft.maxNotesLength
                            ? 'Keep notes to 1,000 characters or fewer.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_submitError != null) ...[
                        _errorText(_submitError!),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      PrimaryButton(
                        label: 'Submit Report',
                        onPressed: _submit,
                        isLoading: _submitting,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _heading(String text) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);

  Widget _errorText(String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.errorText),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _buildRoadStatus() {
    return FormField<RoadStatus>(
      validator: (value) => value == null ? 'Select a road status.' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<RoadStatus>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            selected: {?_roadStatus},
            segments: const [
              ButtonSegment(
                value: RoadStatus.passable,
                label: Text('Passable'),
              ),
              ButtonSegment(
                value: RoadStatus.notPassable,
                label: Text('Not passable'),
              ),
            ],
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (!states.contains(WidgetState.selected)) {
                  return AppColors.surface;
                }
                return _roadStatus == RoadStatus.notPassable
                    ? AppColors.floodRed
                    : AppColors.floodBlue;
              }),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.surface
                    : AppColors.ink,
              ),
              textStyle: WidgetStatePropertyAll(
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            onSelectionChanged: _submitting
                ? null
                : (selection) {
                    setState(() => _roadStatus = selection.firstOrNull);
                    field.didChange(_roadStatus);
                  },
          ),
          if (field.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            _errorText(field.errorText!),
          ],
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return FormField<LatLng>(
      validator: (point) {
        if (point == null) return 'Select a flood location on the map.';
        if (!FloodReportDraft.validCoordinates(
          point.latitude,
          point.longitude,
        )) {
          return 'Select a valid location on the map.';
        }
        return null;
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                key: const Key('report-flood-map'),
                options: MapOptions(
                  initialCenter: const LatLng(15.1454, 120.5922),
                  initialZoom: 15.2,
                  backgroundColor: AppColors.mapSurface,
                  onTap: (_, point) {
                    if (_submitting) return;
                    // Normalize longitude when the user pans across a wrapped map.
                    final selected = LatLng(
                      point.latitude,
                      (point.longitude + 180) % 360 - 180,
                    );
                    setState(() => _location = selected);
                    field.didChange(selected);
                  },
                ),
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      AppColors.mapSurface.withValues(alpha: 0.6),
                      BlendMode.srcATop,
                    ),
                    child: TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bahantabay.app',
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      if (_location != null)
                        Marker(
                          point: _location!,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_pin,
                            key: Key('selected-flood-location'),
                            semanticLabel: 'Selected flood location',
                            color: AppColors.floodRed,
                            size: 40,
                          ),
                        ),
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _location == null
                ? 'Tap the map to select the report location.'
                : 'Selected: ${_location!.latitude.toStringAsFixed(5)}, ${_location!.longitude.toStringAsFixed(5)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (field.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            _errorText(field.errorText!),
          ],
        ],
      ),
    );
  }
}
