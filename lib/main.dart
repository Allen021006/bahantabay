import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bahantabay_app.dart';
import 'core/config/app_config.dart';
import 'features/authentication/data/auth_service.dart';
import 'features/routes/data/route_service.dart';
import 'features/flood_reports/data/flood_report_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService? authService;
  RouteService? routeService;
  FloodReportService? floodReportService;
  if (AppConfig.hasSupabaseConfiguration) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
    authService = SupabaseAuthService(Supabase.instance.client);
    routeService = SupabaseRouteService(Supabase.instance.client);
    floodReportService = SupabaseFloodReportService(Supabase.instance.client);
  }

  runApp(
    // Keep the preview frame in the public demo. Each fresh page load starts
    // with iPhone 13 Pro Max; visitors can switch devices with the toolbar.
    DevicePreview(
      enabled: true,
      defaultDevice: Devices.ios.iPhone13ProMax,
      storage: DevicePreviewStorage.none(),
      builder: (context) => BahantabayApp(
        authService: authService,
        routeService: routeService,
        floodReportService: floodReportService,
      ),
    ),
  );
}
