import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/layout/content_inset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../flood_reports/domain/road_status.dart';
import '../../../flood_reports/domain/flood_report.dart';
import '../../../flood_reports/data/flood_report_service.dart';
import '../../../flood_reports/presentation/screens/report_flood_screen.dart';
import '../../../flood_reports/presentation/widgets/flood_report_entry.dart';
import '../../../routes/domain/route_status.dart';
import '../../../routes/domain/route_status_calculator.dart';
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
  static const _viewTransitionDuration = Duration(milliseconds: 300);
  static const _viewShiftDistance = 20.0;
  // Map view widths at or above this use the PC layout.
  static const _desktopMapMinWidth = 800.0;
  static const _desktopPanelWidth = 360.0;
  static const _desktopPanelInset = AppSpacing.lg;
  // Keeps the framed route clear of the Report Flood button (56 + 16 margin)
  // plus half a route marker.
  static const _desktopFabClearance = 104.0;
  // Bottom inset + route card + gap; the chooser may use the rest of the map.
  static const _desktopChooserReservedHeight = 120.0;
  static const _phoneChooserMaxHeight = 280.0;
  static const _listMaxContentWidth = 720.0;
  static const _listViewKey = ValueKey<String>('home-list-view');
  static const _mapViewKey = ValueKey<String>('home-map-view');
  HomeView _selectedView = HomeView.list;
  List<SavedRoute> _routes = [];
  // Store the ID, not the SavedRoute: route objects are replaced on every
  // reload, and the ID is resolved against the current `_routes` when needed.
  String? _selectedRouteId;
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
      _selectedRouteId = null;
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
      setState(() {
        _routes = routes.where((route) => route.userId == userId).toList();
        // A refresh may have removed the selected route; fall back to default.
        if (!_routes.any((route) => route.id == _selectedRouteId)) {
          _selectedRouteId = null;
        }
      });
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

  Future<void> _openRouteDetails(SavedRoute route) async {
    if (widget.isGuest || route.userId != widget.userId) return;
    final status = _assessRoute(route);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(
          route: route,
          status: status,
          routeService: widget.routeService,
          userId: widget.userId,
        ),
      ),
    );
    if (mounted && changed == true) await _loadRoutes();
  }

  RouteStatus? _assessRoute(SavedRoute route) {
    // An empty successful result is SAFE; loading or failure is not an assessment.
    if (_loadingReports || _reportError != null) return null;
    return RouteStatusCalculator().calculate(route: route, reports: _reports);
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

  void _showDemoRouteMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This is a demo route. Sign in and save your own route to view its details.',
        ),
      ),
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
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : _viewTransitionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: _buildViewTransition,
              layoutBuilder: _layoutViewTransition,
              child: _selectedView == HomeView.list
                  ? KeyedSubtree(
                      key: _listViewKey,
                      child: LayoutBuilder(
                        builder: (context, constraints) => _buildListView(
                          centeredContentInset(
                            constraints.maxWidth,
                            maxContentWidth: _listMaxContentWidth,
                          ),
                        ),
                      ),
                    )
                  : KeyedSubtree(key: _mapViewKey, child: _buildMapView()),
            ),
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

  /// Fades the view and shifts it a short distance into place. Map enters from
  /// the trailing side and List from the leading side; the outgoing view runs
  /// the same path in reverse, so the two views move as one continuous motion.
  Widget _buildViewTransition(Widget child, Animation<double> animation) {
    final direction = child.key == _mapViewKey ? 1.0 : -1.0;
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            direction * _viewShiftDistance * (1 - animation.value),
            0,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Stacks the incoming view over any outgoing ones. Outgoing views are made
  /// non-interactive and hidden from accessibility and focus so they can never
  /// intercept taps or be announced while they fade away. Every child gets a
  /// wrapper keyed like its transition child, preserving that child while it
  /// moves from current to outgoing. A completed switch still disposes it.
  Widget _layoutViewTransition(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    Widget guard(Widget child, {required bool active}) {
      return IgnorePointer(
        key: child.key,
        ignoring: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: ExcludeFocus(excluding: !active, child: child),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final child in previousChildren) guard(child, active: false),
        if (currentChild != null) guard(currentChild, active: true),
      ],
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
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      color: _selectedView == HomeView.map
          ? AppColors.floodBlue
          : AppColors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SegmentedButton<HomeView>(
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.scaffoldBackground,
              foregroundColor: AppColors.ink,
              selectedBackgroundColor: AppColors.warning,
              selectedForegroundColor: AppColors.ink,
            ),
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

  Widget _buildListView(double horizontalInset) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
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
              status: _assessRoute(route),
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
            onTap: () => _showDemoRouteMessage(),
          ),
          const SizedBox(height: AppSpacing.sm),
          RouteCard(
            routeName: 'Work route',
            startLabel: 'Fiesta Community',
            endLabel: 'Angeles University Foundation',
            status: RouteStatus.clear,
            onTap: () => _showDemoRouteMessage(),
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

  /// Resolves the selected ID against the current routes. Falls back to the
  /// first route when nothing is selected or the selected route is gone.
  SavedRoute? _resolveSelectedRoute() {
    if (_routes.isEmpty) return null;
    for (final route in _routes) {
      if (route.id == _selectedRouteId) return route;
    }
    return _routes.first;
  }

  /// Chooses the phone or PC layout from the width the Map view is actually
  /// given, not from the screen size.
  Widget _buildMapView() {
    return LayoutBuilder(
      builder: (context, constraints) => _buildMapContent(
        isDesktop: constraints.maxWidth >= _desktopMapMinWidth,
        availableHeight: constraints.maxHeight,
      ),
    );
  }

  Widget _buildMapContent({
    required bool isDesktop,
    required double availableHeight,
  }) {
    final selected = _resolveSelectedRoute();
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
          key: ValueKey((
            isDesktop,
            selected?.id ??
                (showDemoRoute ? 'demo' : _reports.firstOrNull?.id ?? 'empty'),
            start?.latitude,
            start?.longitude,
            destination?.latitude,
            destination?.longitude,
          )),
          options: MapOptions(
            initialCenter: start == null && _reports.isNotEmpty
                ? LatLng(_reports.first.latitude, _reports.first.longitude)
                : _mapCenter,
            initialZoom: 15.2,
            initialCameraFit: start == null || destination == null
                ? null
                : CameraFit.bounds(
                    bounds: LatLngBounds(start, destination),
                    // PC: reserve the left column used by the panels so the
                    // route is framed in the open map area beside them.
                    padding: isDesktop
                        ? const EdgeInsets.fromLTRB(
                            _desktopPanelInset + _desktopPanelWidth + 48,
                            48,
                            48,
                            _desktopFabClearance,
                          )
                        : const EdgeInsets.fromLTRB(48, 48, 48, 200),
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
          left: isDesktop ? _desktopPanelInset : AppSpacing.sm,
          right: isDesktop ? null : AppSpacing.sm,
          width: isDesktop ? _desktopPanelWidth : null,
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
          right: isDesktop ? null : AppSpacing.lg,
          width: isDesktop ? _desktopPanelWidth : null,
          bottom: isDesktop ? AppSpacing.lg : 88,
          child: showDemoRoute || selected != null
              ? _buildSelectedRouteCard(
                  selected,
                  // Keep the saved-route list inside the map area above the
                  // card; it scrolls when it is taller than this.
                  chooserMaxHeight: isDesktop
                      ? (availableHeight - _desktopChooserReservedHeight)
                            .clamp(96.0, _phoneChooserMaxHeight)
                            .toDouble()
                      : _phoneChooserMaxHeight,
                )
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

  Widget _buildSelectedRouteCard(
    SavedRoute? selected, {
    double chooserMaxHeight = _phoneChooserMaxHeight,
  }) {
    final canChooseRoute =
        selected != null && !widget.isGuest && _routes.length > 1;
    final routeSummary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selected?.name ?? 'School route (demo)',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          selected == null
              ? 'St. Ignatius Subd. to Holy Angel University'
              : _assessRoute(selected)?.label ?? 'Status not assessed',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
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
              child: canChooseRoute
                  ? PopupMenuButton<String>(
                      key: const Key('map-route-chooser'),
                      tooltip: 'Choose saved route',
                      initialValue: selected.id,
                      borderRadius: BorderRadius.circular(8),
                      constraints: BoxConstraints(
                        minWidth: 220,
                        maxWidth: 360,
                        maxHeight: chooserMaxHeight,
                      ),
                      // Place the route list above the bottom card in the
                      // available map space, with a scrollable height cap.
                      offset: Offset(
                        0,
                        -(_routes.length * 48.0 + 16.0)
                                .clamp(0.0, chooserMaxHeight)
                                .toDouble() -
                            AppSpacing.sm -
                            AppSpacing.lg,
                      ),
                      itemBuilder: (context) => [
                        for (final route in _routes)
                          CheckedPopupMenuItem<String>(
                            value: route.id,
                            checked: route.id == selected.id,
                            child: Text(
                              route.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onSelected: (id) => setState(() => _selectedRouteId = id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: routeSummary),
                            const Icon(Icons.keyboard_arrow_up),
                          ],
                        ),
                      ),
                    )
                  : routeSummary,
            ),
            TextButton(
              onPressed: () => selected == null
                  ? _showDemoRouteMessage()
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
