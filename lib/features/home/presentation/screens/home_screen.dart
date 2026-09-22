import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../flood_reports/domain/road_status.dart';
import '../../../flood_reports/domain/flood_report.dart';
import '../../../flood_reports/data/flood_report_service.dart';
import '../../../flood_reports/presentation/screens/report_flood_screen.dart';
import '../../../flood_reports/presentation/widgets/flood_report_entry.dart';
import '../../../routes/domain/route_status.dart';
import '../../../routes/domain/saved_route.dart';
import '../../../routes/data/route_service.dart';
import '../../../routes/presentation/screens/add_route_screen.dart';
import '../../../routes/presentation/screens/route_details_screen.dart';
import '../../../routes/presentation/widgets/route_card.dart';
import '../../../routes/presentation/widgets/status_badge.dart';

enum HomeView { list, map }

enum _AccountAction { logOut, switchAccount, openAuth }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isGuest,
    required this.onReturnToAuth,
    this.email,
    this.showDemoData = true,
    this.userId,
    this.routeService,
    this.floodReportService,
  });

  final bool isGuest;
  final String? email;
  final Future<void> Function() onReturnToAuth;
  final bool showDemoData;
  final String? userId;
  final RouteService? routeService;
  final FloodReportService? floodReportService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _mapCenter = LatLng(15.1454, 120.5922);
  static const _routeStart = LatLng(15.1458, 120.5887);
  static const _routeDestination = LatLng(15.1450, 120.5957);
  HomeView _selectedView = HomeView.list;
  List<SavedRoute> _routes = [];
  bool _loadingRoutes = false;
  String? _routeError;
  int _loadVersion = 0;
  List<FloodReport> _reports = [];
  bool _loadingReports = false;
  String? _reportError;
  int _reportLoadVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadReports();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.isGuest != widget.isGuest ||
        oldWidget.routeService != widget.routeService) {
      _loadRoutes();
    }
    if (oldWidget.floodReportService != widget.floodReportService ||
        oldWidget.userId != widget.userId ||
        oldWidget.isGuest != widget.isGuest) {
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    final version = ++_reportLoadVersion;
    setState(() {
      _reports = [];
      _reportError = null;
      _loadingReports = true;
    });
    try {
      final service = widget.floodReportService;
      if (service == null) {
        throw const FloodReportFailure(
          'Flood reports are unavailable. Please try again later.',
        );
      }
      final reports = await service.fetchReports();
      if (!mounted || version != _reportLoadVersion) return;
      setState(() => _reports = reports);
    } catch (error) {
      if (!mounted || version != _reportLoadVersion) return;
      setState(
        () => _reportError = error is FloodReportFailure
            ? error.message
            : 'Could not load flood reports. Please try again.',
      );
    } finally {
      if (mounted && version == _reportLoadVersion) {
        setState(() => _loadingReports = false);
      }
    }
  }

  Future<void> _openReportFlood() async {
    if (widget.isGuest || widget.userId == null) return;
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportFloodScreen(
          service: widget.floodReportService,
          userId: widget.userId,
        ),
      ),
    );
    if (mounted && submitted == true) await _loadReports();
  }

  Widget _buildReports() {
    if (_loadingReports) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(
            key: Key('flood-reports-loading'),
            semanticsLabel: 'Loading flood reports',
          ),
        ),
      );
    }
    if (_reportError != null) {
      return Column(
        children: [
          Text(
            _reportError!,
            style: const TextStyle(color: AppColors.errorText),
          ),
          TextButton(
            onPressed: _loadReports,
            child: const Text('Retry flood reports'),
          ),
        ],
      );
    }
    if (_reports.isEmpty) {
      return const EmptyState(
        message: 'No flood reports yet.',
        icon: Icons.water_drop_outlined,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          for (var index = 0; index < _reports.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            FloodReportEntry(
              location: _coordinates(
                _reports[index].latitude,
                _reports[index].longitude,
              ),
              floodDepth: '${_reports[index].depth.label}-deep',
              roadStatus: _reports[index].roadStatus,
              notes: _reports[index].notes,
              createdAt: _reports[index].createdAt,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadRoutes() async {
    final version = ++_loadVersion;
    setState(() {
      _routes = [];
      _routeError = null;
      _loadingRoutes = !widget.isGuest;
    });
    if (widget.isGuest) return;
    try {
      final service = widget.routeService;
      final userId = widget.userId;
      if (service == null || userId == null) {
        throw const RouteFailure(
          'Routes are unavailable. Please sign in again.',
        );
      }
      final routes = await service.fetchRoutes(userId);
      if (!mounted || version != _loadVersion) return;
      setState(
        () =>
            _routes = routes.where((route) => route.userId == userId).toList(),
      );
    } catch (error) {
      if (!mounted || version != _loadVersion) return;
      setState(
        () => _routeError = error is RouteFailure
            ? error.message
            : 'Could not load your routes. Please try again.',
      );
    } finally {
      if (mounted && version == _loadVersion) {
        setState(() => _loadingRoutes = false);
      }
    }
  }

  Future<void> _openAddRoute() async {
    if (widget.isGuest) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRouteScreen(
          routeService: widget.routeService,
          userId: widget.userId,
        ),
      ),
    );
    if (mounted && saved == true) await _loadRoutes();
  }

  void _openRouteDetails(SavedRoute route) {
    if (widget.isGuest || route.userId != widget.userId) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => RouteDetailsScreen(route: route)),
    );
  }

  String _coordinates(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  Widget _buildRouteState() {
    if (_loadingRoutes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading saved routes',
          ),
        ),
      );
    }
    if (_routeError != null) {
      return Column(
        children: [
          Text(
            _routeError!,
            style: const TextStyle(color: AppColors.errorText),
          ),
          TextButton(onPressed: _loadRoutes, child: const Text('Retry routes')),
        ],
      );
    }
    return const EmptyState(
      message: 'No saved routes yet.',
      icon: Icons.route_outlined,
    );
  }

  void _showLaterMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be connected in a later phase.')),
    );
  }

  Future<void> _handleAccountAction(_AccountAction action) async {
    switch (action) {
      case _AccountAction.logOut:
      case _AccountAction.switchAccount:
      case _AccountAction.openAuth:
        await widget.onReturnToAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedView == HomeView.map
          ? AppColors.floodBlue
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        centerTitle: false,
        title: SizedBox(
          width: 160,
          height: 48,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            // The square asset has transparent margins around the brand mark.
            // Crop only those margins, then scale the whole mark uniformly.
            child: ClipRect(
              child: Align(
                alignment: const Alignment(0.12, -0.075),
                widthFactor: 0.82,
                heightFactor: 0.28,
                child: Image.asset(
                  'docs/assets/Home Page Logo.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<_AccountAction>(
            tooltip: 'Account menu',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: _handleAccountAction,
            itemBuilder: _buildAccountMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          Expanded(
            child: _selectedView == HomeView.list
                ? _buildListView()
                : _buildMapView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.isGuest ? null : _openReportFlood,
        icon: const Icon(Icons.add),
        label: const Text('Report Flood'),
      ),
    );
  }

  List<PopupMenuEntry<_AccountAction>> _buildAccountMenu(BuildContext context) {
    if (widget.isGuest) {
      return const [
        PopupMenuItem(enabled: false, child: Text('Guest session')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _AccountAction.openAuth,
          child: Text('Sign in / Create account'),
        ),
      ];
    }

    return [
      PopupMenuItem(
        enabled: false,
        child: Text(widget.email ?? 'Signed-in account'),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(value: _AccountAction.logOut, child: Text('Log out')),
      const PopupMenuItem(
        value: _AccountAction.switchAccount,
        child: Text('Switch account'),
      ),
    ];
  }

  Widget _buildViewSelector() {
    return ColoredBox(
      color: _selectedView == HomeView.map
          ? AppColors.floodBlue
          : AppColors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SegmentedButton<HomeView>(
            segments: const [
              ButtonSegment(
                value: HomeView.list,
                label: Text('List'),
                icon: Icon(Icons.list),
              ),
              ButtonSegment(
                value: HomeView.map,
                label: Text('Map'),
                icon: Icon(Icons.map_outlined),
              ),
            ],
            selected: {_selectedView},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedView = selection.first;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg * 4,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Saved routes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            TextButton.icon(
              onPressed: widget.isGuest ? null : _openAddRoute,
              icon: const Icon(Icons.add),
              label: const Text('Add route'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.isGuest && widget.showDemoData)
          Text('Demo routes', style: Theme.of(context).textTheme.labelSmall),
        if (!widget.isGuest) ...[
          if (_routes.isEmpty) _buildRouteState(),
          for (final route in _routes) ...[
            RouteCard(
              routeName: route.name,
              startLabel: _coordinates(
                route.startLatitude,
                route.startLongitude,
              ),
              endLabel: _coordinates(
                route.destinationLatitude,
                route.destinationLongitude,
              ),
              status: null,
              onTap: () => _openRouteDetails(route),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ] else if (widget.showDemoData) ...[
          RouteCard(
            routeName: 'School route',
            startLabel: 'St. Ignatius Subd.',
            endLabel: 'Holy Angel University',
            status: RouteStatus.warning,
            onTap: () => _showLaterMessage('Route Details'),
          ),
          const SizedBox(height: AppSpacing.sm),
          RouteCard(
            routeName: 'Work route',
            startLabel: 'Fiesta Community',
            endLabel: 'Angeles University Foundation',
            status: RouteStatus.clear,
            onTap: () => _showLaterMessage('Route Details'),
          ),
        ] else
          const Material(
            color: AppColors.surface,
            child: EmptyState(
              message: 'No saved routes yet.',
              icon: Icons.route_outlined,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Flood reports',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh flood reports',
              onPressed: _loadingReports ? null : _loadReports,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Text(
          'Latest 100 community reports • not filtered by distance',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildReports(),
      ],
    );
  }

  Widget _buildMapView() {
    final selected = _routes.isEmpty ? null : _routes.first;
    final showDemoRoute = widget.isGuest && widget.showDemoData;
    final start = showDemoRoute
        ? _routeStart
        : selected == null
        ? null
        : LatLng(selected.startLatitude, selected.startLongitude);
    final destination = showDemoRoute
        ? _routeDestination
        : selected == null
        ? null
        : LatLng(selected.destinationLatitude, selected.destinationLongitude);
    return Stack(
      children: [
        FlutterMap(
          key: ValueKey(
            'home-map-${selected?.id ?? (showDemoRoute ? 'demo' : _reports.firstOrNull?.id ?? 'empty')}',
          ),
          options: MapOptions(
            initialCenter: start == null && _reports.isNotEmpty
                ? LatLng(_reports.first.latitude, _reports.first.longitude)
                : _mapCenter,
            initialZoom: 15.2,
            initialCameraFit: start == null || destination == null
                ? null
                : CameraFit.bounds(
                    bounds: LatLngBounds(start, destination),
                    padding: const EdgeInsets.fromLTRB(48, 48, 48, 200),
                    maxZoom: 16,
                  ),
          ),
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.floodBlue.withValues(alpha: 0.5),
                BlendMode.srcATop,
              ),
              child: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahantabay.app',
              ),
            ),
            if (start != null && destination != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [start, destination],
                    color: AppColors.surface,
                    strokeWidth: 4,
                    pattern: StrokePattern.dashed(segments: [12, 8]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (start != null)
                  Marker(
                    point: start,
                    width: 44,
                    height: 44,
                    child: _RoutePointMarker(
                      key: Key('route-start-marker'),
                      label: 'Route start point',
                      color: AppColors.warning,
                      icon: Icons.trip_origin,
                    ),
                  ),
                if (destination != null)
                  Marker(
                    point: destination,
                    width: 44,
                    height: 44,
                    child: _RoutePointMarker(
                      key: Key('route-destination-marker'),
                      label: 'Route destination point',
                      color: AppColors.floodRed,
                      icon: Icons.flag,
                    ),
                  ),
                for (final report in _reports)
                  Marker(
                    point: LatLng(report.latitude, report.longitude),
                    width: 44,
                    height: 44,
                    child: _FloodMapMarker(
                      key: ValueKey('flood-marker-${report.id}'),
                      report: report,
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
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _loadingReports
                          ? 'Loading flood reports...'
                          : _reportError ??
                                (_reports.isEmpty
                                    ? 'No flood reports yet.'
                                    : '${_reports.length} public flood reports'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh flood reports',
                    onPressed: _loadingReports ? null : _loadReports,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 88,
          child: showDemoRoute || selected != null
              ? _buildSelectedRouteCard(selected)
              : Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _buildRouteState(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedRouteCard(SavedRoute? selected) {
    return Material(
      key: const Key('selected-route-warning-card'),
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (selected == null)
              const StatusBadge(status: RouteStatus.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected?.name ?? 'School route (demo)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    selected == null
                        ? 'St. Ignatius Subd. to Holy Angel University'
                        : 'Status not assessed',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => selected == null
                  ? _showLaterMessage('Route Details')
                  : _openRouteDetails(selected),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePointMarker extends StatelessWidget {
  const _RoutePointMarker({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 3),
        ),
        child: Icon(icon, color: AppColors.surface, size: 22),
      ),
    );
  }
}

class _FloodMapMarker extends StatelessWidget {
  const _FloodMapMarker({super.key, required this.report});

  final FloodReport report;

  @override
  Widget build(BuildContext context) {
    final label = '${report.depth.label}-deep • ${report.roadStatus.label}';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: report.roadStatus == RoadStatus.notPassable
                ? AppColors.floodRed
                : AppColors.warning,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.water_drop,
            color: report.roadStatus == RoadStatus.notPassable
                ? AppColors.surface
                : AppColors.ink,
            size: 24,
          ),
        ),
      ),
    );
  }
}
