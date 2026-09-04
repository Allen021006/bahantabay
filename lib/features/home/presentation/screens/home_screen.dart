import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../flood_reports/domain/road_status.dart';
import '../../../flood_reports/presentation/widgets/flood_report_entry.dart';
import '../../../routes/domain/route_status.dart';
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
  });

  final bool isGuest;
  final String? email;
  final Future<void> Function() onReturnToAuth;
  final bool showDemoData;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _mapCenter = LatLng(15.1454, 120.5922);
  static const _routeStart = LatLng(15.1458, 120.5887);
  static const _routeDestination = LatLng(15.1450, 120.5957);
  static const _floodReports = [
    LatLng(15.1470, 120.5920),
    LatLng(15.1437, 120.5905),
  ];

  HomeView _selectedView = HomeView.list;

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
        title: Image.asset(
          'docs/assets/Home Page Logo.png',
          width: 160,
          height: 48,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
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
        onPressed: widget.isGuest
            ? null
            : () => _showLaterMessage('Report Flood'),
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
              onPressed: widget.isGuest
                  ? null
                  : () => _showLaterMessage('Add Route'),
              icon: const Icon(Icons.add),
              label: const Text('Add route'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.showDemoData) ...[
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
        Text(
          'Nearby flood reports',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.showDemoData)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: AppColors.surface,
              child: Column(
                children: [
                  FloodReportEntry(
                    location: 'Fiesta Community',
                    floodDepth: 'Knee-deep',
                    roadStatus: RoadStatus.notPassable,
                    createdAt: DateTime.now().subtract(
                      const Duration(minutes: 10),
                    ),
                  ),
                  const Divider(height: 1),
                  FloodReportEntry(
                    location: 'MacArthur Highway',
                    floodDepth: 'Ankle-deep',
                    roadStatus: RoadStatus.passable,
                    createdAt: DateTime.now().subtract(
                      const Duration(minutes: 25),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Material(
            color: AppColors.surface,
            child: EmptyState(
              message: 'No nearby flood reports.',
              icon: Icons.water_drop_outlined,
            ),
          ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          key: const Key('home-map'),
          options: const MapOptions(
            initialCenter: _mapCenter,
            initialZoom: 15.2,
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
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [_routeStart, _routeDestination],
                  color: AppColors.surface,
                  strokeWidth: 4,
                  pattern: StrokePattern.dashed(segments: [12, 8]),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                const Marker(
                  point: _routeStart,
                  width: 44,
                  height: 44,
                  child: _RoutePointMarker(
                    key: Key('route-start-marker'),
                    label: 'Route start point',
                    color: AppColors.warning,
                    icon: Icons.trip_origin,
                  ),
                ),
                const Marker(
                  point: _routeDestination,
                  width: 44,
                  height: 44,
                  child: _RoutePointMarker(
                    key: Key('route-destination-marker'),
                    label: 'Route destination point',
                    color: AppColors.floodRed,
                    icon: Icons.flag,
                  ),
                ),
                for (var index = 0; index < _floodReports.length; index++)
                  Marker(
                    point: _floodReports[index],
                    width: 44,
                    height: 44,
                    child: _FloodMapMarker(
                      key: ValueKey('flood-marker-$index'),
                      number: index + 1,
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
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 88,
          child: _buildSelectedRouteCard(),
        ),
      ],
    );
  }

  Widget _buildSelectedRouteCard() {
    return Material(
      key: const Key('selected-route-warning-card'),
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const StatusBadge(status: RouteStatus.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'School route',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'St. Ignatius Subd. to Holy Angel University',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showLaterMessage('Route Details'),
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
  const _FloodMapMarker({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Flood report $number',
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.floodRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.water_drop, color: AppColors.surface, size: 24),
      ),
    );
  }
}
