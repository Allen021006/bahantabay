import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/wave_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _waterRise;
  late final Animation<double> _brandFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _waterRise = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.03, 0.92, curve: Curves.easeInOutSine),
    );

    _brandFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.floodBlue,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Back wave
              Positioned.fill(
                child: CustomPaint(
                  painter: WavePainter(
                    progress: _waterRise.value * 0.9,
                    phase: (_controller.value * 1.5 * math.pi) + 1.5,
                    color: AppColors.mapSurface.withValues(alpha: 0.18),
                    amplitude: 18,
                    wavelength: 210,
                  ),
                ),
              ),

              // Surface highlight
              Positioned.fill(
                child: CustomPaint(
                  painter: WavePainter(
                    progress: _waterRise.value * 0.96,
                    phase: (_controller.value * 1.8 * math.pi) + 0.7,
                    color: AppColors.mapSurface.withValues(alpha: 0.12),
                    amplitude: 7,
                    wavelength: 165,
                  ),
                ),
              ),

              // Front wave
              Positioned.fill(
                child: CustomPaint(
                  painter: WavePainter(
                    progress: _waterRise.value,
                    phase: _controller.value * 2.2 * math.pi,
                    color: AppColors.mapSurface.withValues(alpha: 0.26),
                    amplitude: 10,
                    wavelength: 135,
                  ),
                ),
              ),

              // Branding
              Center(
                child: Opacity(
                  opacity: _brandFade.value,
                  child: const Text(
                    'BAHANTABAY',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
