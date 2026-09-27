import 'dart:convert';
import 'dart:io';
import 'package:bahantabay/features/routes/data/route_service.dart';
import 'package:bahantabay/features/routes/domain/saved_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  mutationTests();
  test(
    'route service rejects reads and saves without an authenticated session',
    () async {
      final client = SupabaseClient('https://example.invalid', 'test-key');
      addTearDown(client.dispose);
      final service = SupabaseRouteService(client);
      await expectLater(
        service.deleteRoute('user-a', 'route-1'),
        throwsA(isA<RouteFailure>()),
      );
      await expectLater(
        service.updateRoute(
          'user-a',
          'route-1',
          const RouteDraft(
            name: 'Edit',
            startLatitude: 15,
            startLongitude: 120,
            destinationLatitude: 16,
            destinationLongitude: 121,
          ),
        ),
        throwsA(isA<RouteFailure>()),
      );
      await expectLater(
        service.fetchRoutes('user-a'),
        throwsA(isA<RouteFailure>()),
      );
      await expectLater(
        service.saveRoute(
          'user-a',
          const RouteDraft(
            name: 'Private route',
            startLatitude: 15,
            startLongitude: 120,
            destinationLatitude: 16,
            destinationLongitude: 121,
          ),
        ),
        throwsA(isA<RouteFailure>()),
      );
    },
  );
}

void mutationTests() {
  const userId = '00000000-0000-4000-8000-000000000001';
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseRouteService service;
  late List<Map<String, dynamic>> requests;
  var failDatabase = false;
  var emptyResult = false;

  setUp(() async {
    requests = [];
    failDatabase = false;
    emptyResult = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/auth/v1/token') {
        final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
        String encode(Map<String, dynamic> value) => base64Url
            .encode(utf8.encode(jsonEncode(value)))
            .replaceAll('=', '');
        final token =
            '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
            '${encode({'sub': userId, 'exp': expiry, 'role': 'authenticated'})}.test-signature';
        request.response.write(
          jsonEncode({
            'access_token': token,
            'refresh_token': 'test-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'expires_at': expiry,
            'user': {
              'id': userId,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'tester@example.com',
              'is_anonymous': false,
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-09-17T00:00:00Z',
            },
          }),
        );
      } else {
        requests.add({
          'method': request.method,
          'uri': request.uri,
          'body': body.isEmpty ? null : jsonDecode(body),
        });
        if (failDatabase) {
          request.response.statusCode = 403;
          request.response.write(
            jsonEncode({
              'code': '42501',
              'message': 'private SQL details',
              'details': null,
              'hint': null,
            }),
          );
        } else {
          request.response.statusCode = 201;
          request.response.write(emptyResult ? '[]' : '[{"id":"route-1"}]');
        }
      }
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    service = SupabaseRouteService(client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'tester@example.com',
    password: 'test-password',
  );

  const draft = RouteDraft(
    name: ' Renamed ',
    startLatitude: 15,
    startLongitude: 120,
    destinationLatitude: 16,
    destinationLongitude: 121,
  );
  for (final deleting in [false, true]) {
    test(
      '${deleting ? "delete" : "update"} filters exact route and authenticated owner',
      () async {
        await signIn();
        if (deleting) {
          await service.deleteRoute(userId, 'route-1');
        } else {
          await service.updateRoute(userId, 'route-1', draft);
        }
        final request = requests.single;
        expect(request['method'], deleting ? 'DELETE' : 'PATCH');
        final uri = request['uri'] as Uri;
        expect(uri.queryParameters['id'], 'eq.route-1');
        expect(uri.queryParameters['user_id'], 'eq.$userId');
        expect(uri.queryParameters['select'], 'id');
        if (!deleting) expect(request['body'], draft.toInsertMap());
      },
    );
    test(
      '${deleting ? "delete" : "update"} rejects mismatched session and unavailable rows',
      () async {
        await signIn();
        Future<void> mutate(String owner) => deleting
            ? service.deleteRoute(owner, 'route-1')
            : service.updateRoute(owner, 'route-1', draft);
        await expectLater(mutate('another-user'), throwsA(isA<RouteFailure>()));
        expect(requests, isEmpty);
        emptyResult = true;
        await expectLater(mutate(userId), throwsA(isA<RouteFailure>()));
        failDatabase = true;
        await expectLater(
          mutate(userId),
          throwsA(
            isA<RouteFailure>().having(
              (e) => e.message,
              'safe error',
              isNot(contains('private SQL')),
            ),
          ),
        );
      },
    );
  }
}
