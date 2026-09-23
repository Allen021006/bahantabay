import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/authentication/data/auth_service.dart';
import '../features/splash/presentation/splash_gate.dart';
import '../features/routes/data/route_service.dart';
import '../features/flood_reports/data/flood_report_service.dart';

class BahantabayApp extends StatelessWidget {
  const BahantabayApp({
    super.key,
    this.authService,
    this.routeService,
    this.floodReportService,
  });

  final AuthService? authService;
  final RouteService? routeService;
  final FloodReportService? floodReportService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bahantabay',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light,
      home: SplashGate(
        authService: authService,
        routeService: routeService,
        floodReportService: floodReportService,
      ),
    );
  }
}
