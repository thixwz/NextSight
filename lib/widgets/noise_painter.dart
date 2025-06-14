import 'dart:math';
import 'package:flutter/material.dart';

class NoiseBackground extends StatelessWidget {
  final Color color;
  final double opacity;
  final double density;

  const NoiseBackground({
    super.key,
    this.color = Colors.white, // Base color for noise dots
    this.opacity = 0.05,      // How visible the dots are
    this.density = 0.5,       // How many dots (0.0 to 1.0)
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NoisePainter(
        color: color,
        opacity: opacity,
        density: density,
      ),
      child: Container(), // Painter needs a child to determine size
    );
  }
}

class NoisePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double density;
  final Random _random = Random();

  NoisePainter({
    required this.color,
    required this.opacity,
    required this.density,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Calculate number of dots based on density and screen area
    int numberOfDots = (size.width * size.height * density * 0.1).toInt(); 

    for (int i = 0; i < numberOfDots; i++) {
      double x = _random.nextDouble() * size.width;
      double y = _random.nextDouble() * size.height;
      // Draw small rectangles (1x1 pixel)
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint only if properties change
    return oldDelegate is NoisePainter &&
           (oldDelegate.color != color ||
            oldDelegate.opacity != opacity ||
            oldDelegate.density != density);
  }
}