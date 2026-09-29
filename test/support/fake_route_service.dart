import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';

SavedRoute exampleRoute({
  String id = 'route-1',
  String userId = 'user-a',
  String name = 'School route',
  double startLatitude = 15.1458,
  double startLongitude = 120.5887,
  double destinationLatitude = 15.145,
  double destinationLongitude = 120.5957,
}) => SavedRoute(
  id: id,
  userId: userId,
  name: name,
  startLatitude: startLatitude,
  startLongitude: startLongitude,
  destinationLatitude: destinationLatitude,
  destinationLongitude: destinationLongitude,
  createdAt: DateTime.utc(2026, 9, 15),
);

class FakeRouteService implements RouteService {
  List<SavedRoute> routes = [];
  int fetchCalls = 0;
  int saveCalls = 0;
  RouteDraft? lastDraft;
  Future<List<SavedRoute>> Function(String)? onFetch;
  Future<void> Function()? onSave;

  @override
  Future<List<SavedRoute>> fetchRoutes(String userId) async {
    fetchCalls++;
    if (onFetch != null) return onFetch!(userId);
    return routes.where((route) => route.userId == userId).toList();
  }

  @override
  Future<void> saveRoute(String userId, RouteDraft draft) async {
    saveCalls++;
    lastDraft = draft;
    if (onSave != null) await onSave!();
    routes.add(exampleRoute(userId: userId, name: draft.name.trim()));
  }

  int updateCalls = 0;
  int deleteCalls = 0;
  Future<void> Function()? onUpdate;
  Future<void> Function()? onDelete;

  @override
  Future<void> updateRoute(
    String userId,
    String routeId,
    RouteDraft draft,
  ) async {
    updateCalls++;
    lastDraft = draft;
    if (onUpdate != null) await onUpdate!();
    final index = routes.indexWhere(
      (r) => r.id == routeId && r.userId == userId,
    );
    if (index < 0) {
      throw const RouteFailure('Route no longer available. Refresh Home.');
    }
    final previous = routes[index];
    routes[index] = SavedRoute(
      id: previous.id,
      userId: previous.userId,
      createdAt: previous.createdAt,
      name: draft.name.trim(),
      startLatitude: draft.startLatitude,
      startLongitude: draft.startLongitude,
      destinationLatitude: draft.destinationLatitude,
      destinationLongitude: draft.destinationLongitude,
    );
  }

  @override
  Future<void> deleteRoute(String userId, String routeId) async {
    deleteCalls++;
    if (onDelete != null) await onDelete!();
    routes.removeWhere((r) => r.id == routeId && r.userId == userId);
  }
}
