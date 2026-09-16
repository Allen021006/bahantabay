import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';

SavedRoute exampleRoute({
  String userId = 'user-a',
  String name = 'School route',
}) => SavedRoute(
  id: 'route-1',
  userId: userId,
  name: name,
  startLatitude: 15.1458,
  startLongitude: 120.5887,
  destinationLatitude: 15.145,
  destinationLongitude: 120.5957,
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
}
