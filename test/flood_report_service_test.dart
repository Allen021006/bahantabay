import 'dart:convert';
import 'dart:io';

import 'package:bahantabay/features/flood_reports/data/flood_report_service.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_depth.dart';
import 'package:bahantabay/features/flood_reports/domain/flood_report.dart';
import 'package:bahantabay/features/flood_reports/domain/road_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Loopback-only fake HTTP backend. These tests exercise the actual Supabase SDK
// without a Supabase project, real credentials, or an external network call.
void main() {
  const userId = '00000000-0000-4000-8000-000000000001';
  const draft = FloodReportDraft(
    latitude: 15,
    longitude: 120,
    depth: FloodDepth.waist,
    roadStatus: RoadStatus.notPassable,
    notes: '  Flooded crossing.  ',
  );
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseFloodReportService service;
  late List<Map<String, dynamic>> requests;
  var failDatabase = false;

  setUp(() async {
    requests = [];
    failDatabase = false;
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
        } else if (request.method == 'GET') {
          request.response.write(
            jsonEncode([
              {
                'id': 'report-1',
                'latitude': 15,
                'longitude': 120,
                'flood_depth': 'knee',
                'road_status': 'passable',
                'notes': null,
                'created_at': '2026-09-17T00:00:00Z',
              },
            ]),
          );
        } else {
          request.response.statusCode = 201;
          request.response.write('{}');
        }
      }
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    service = SupabaseFloodReportService(client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'tester@example.com',
    password: 'test-password',
  );

  test(
    'guest fetches public reports newest first without ownership filter',
    () async {
      final reports = await service.fetchReports();
      expect(client.auth.currentSession, isNull);
      expect(reports.single.depth, FloodDepth.knee);
      expect(reports.single.roadStatus, RoadStatus.passable);
      final uri = requests.single['uri'] as Uri;
      expect(uri.path, '/rest/v1/flood_reports');
      expect(
        uri.queryParameters['select'],
        'id,latitude,longitude,flood_depth,road_status,notes,created_at',
      );
      expect(uri.queryParameters['order'], 'created_at.desc.nullslast');
      expect(uri.queryParameters['limit'], '100');
      expect(uri.queryParameters.containsKey('reporter_id'), isFalse);
    },
  );

  test(
    'unauthenticated submission is rejected before any database request',
    () async {
      await expectLater(
        service.submitReport(userId, draft),
        throwsA(isA<FloodReportFailure>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'authenticated submission pins ownership and leaves ID/time to database',
    () async {
      await signIn();
      await service.submitReport(userId, draft);
      expect(requests.single['method'], 'POST');
      expect(requests.single['body'], {
        'latitude': 15.0,
        'longitude': 120.0,
        'flood_depth': 'waist',
        'road_status': 'not_passable',
        'notes': 'Flooded crossing.',
        'reporter_id': userId,
      });
      final reports = await service.fetchReports();
      expect(reports, hasLength(1));
      final uri = requests.last['uri'] as Uri;
      expect(
        uri.queryParameters['select'],
        'id,latitude,longitude,flood_depth,road_status,notes,created_at',
      );
      expect(uri.queryParameters['order'], 'created_at.desc.nullslast');
      expect(uri.queryParameters['limit'], '100');
    },
  );

  test('wrong account and invalid coordinates cannot submit', () async {
    await signIn();
    await expectLater(
      service.submitReport('another-user', draft),
      throwsA(isA<FloodReportFailure>()),
    );
    await expectLater(
      service.submitReport(
        userId,
        const FloodReportDraft(
          latitude: 91,
          longitude: 120,
          depth: FloodDepth.ankle,
          roadStatus: RoadStatus.passable,
        ),
      ),
      throwsA(isA<FloodReportFailure>()),
    );
    await expectLater(
      service.submitReport(
        userId,
        FloodReportDraft(
          latitude: 15,
          longitude: 120,
          depth: FloodDepth.ankle,
          roadStatus: RoadStatus.passable,
          notes: 'x' * 1001,
        ),
      ),
      throwsA(isA<FloodReportFailure>()),
    );
    expect(requests, isEmpty);
  });

  test('database failures return safe fetch/submit errors', () async {
    failDatabase = true;
    await expectLater(
      service.fetchReports(),
      throwsA(
        isA<FloodReportFailure>().having(
          (error) => error.message,
          'message',
          'Could not load flood reports. Please try again.',
        ),
      ),
    );
    await signIn();
    await expectLater(
      service.submitReport(userId, draft),
      throwsA(
        isA<FloodReportFailure>().having(
          (error) => error.message,
          'message',
          isNot(contains('private SQL details')),
        ),
      ),
    );
  });
}
