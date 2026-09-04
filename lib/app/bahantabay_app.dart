import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/authentication/data/auth_service.dart';
import '../features/authentication/presentation/auth_gate.dart';

class BahantabayApp extends StatelessWidget {
  const BahantabayApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bahantabay',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light,
      home: AuthGate(authService: authService),
    );
  }
}
