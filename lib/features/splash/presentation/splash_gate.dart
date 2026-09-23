import 'package:flutter/material.dart';

import '../../authentication/data/auth_service.dart';
import '../../authentication/presentation/auth_gate.dart';
import '../../flood_reports/data/flood_report_service.dart';
import '../../routes/data/route_service.dart';
import 'screens/splash_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    this.authService,
    this.routeService,
    this.floodReportService,
  });

  final AuthService? authService;
  final RouteService? routeService;
  final FloodReportService? floodReportService;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;
  bool _isFinishing = false;

  Future<void> _finishSplash() async {
    if (!mounted || _isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Keep the app painted underneath, but unavailable for interaction.
        ExcludeFocus(
          excluding: _showSplash,
          child: ExcludeSemantics(
            excluding: _showSplash,
            child: AuthGate(
              authService: widget.authService,
              routeService: widget.routeService,
              floodReportService: widget.floodReportService,
            ),
          ),
        ),

        if (_showSplash)
          Positioned.fill(
            child: AbsorbPointer(
              child: AnimatedOpacity(
                opacity: _isFinishing ? 0 : 1,
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeInOutCubic,
                child: SplashScreen(onFinished: _finishSplash),
              ),
            ),
          ),
      ],
    );
  }
}
