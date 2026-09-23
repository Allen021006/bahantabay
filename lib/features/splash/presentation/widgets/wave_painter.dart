import 'dart:math' as math;

import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  const WavePainter({
    required this.progress,
    required this.phase,
    required this.color,
    this.amplitude = 12.0,
    this.wavelength = 140.0,
  });

  final double progress;
  final double phase;
  final Color color;
  final double amplitude;
  final double wavelength;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) {
      return;
    }

    final paint = Paint()..color = color;

    final waterLevel =
        (size.height + amplitude + 20) -
        ((size.height + amplitude + 40) * progress);

    final path = Path();
    path.moveTo(0, waterLevel);

    for (double x = 0; x <= size.width; x++) {
      final y =
          waterLevel +
          math.sin((x / wavelength * 2 * math.pi) + phase) * amplitude;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.wavelength != wavelength;
  }
}
