import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:panic_button_flutter/theme/app_theme.dart';

class WaveAnimation extends StatelessWidget {
  final Animation<double> waveAnimation;
  final double fillLevel;

  const WaveAnimation({
    super.key,
    required this.waveAnimation,
    required this.fillLevel,
  });

  @override
  Widget build(BuildContext context) {
    final breathColors = Theme.of(context).extension<BreathColors>()!;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: waveAnimation,
        builder: (context, _) {
          return ClipOval(
            child: CustomPaint(
              painter: WavePainter(
                waveAnimation: waveAnimation.value,
                fillLevel: fillLevel,
                oceanDeep: breathColors.oceanDeep,
                oceanMid: breathColors.oceanMid,
                oceanSurface: breathColors.oceanSurface,
              ),
              size: const Size(280, 280),
            ),
          );
        },
      ),
    );
  }
}

// A custom painter that creates fluid wave animation
class WavePainter extends CustomPainter {
  final double waveAnimation; // 0.0 to 1.0
  final double fillLevel; // 0.0 to 1.0, where 1.0 is filled to top
  final Color oceanDeep;
  final Color oceanMid;
  final Color oceanSurface;

  WavePainter({
    required this.waveAnimation,
    required this.fillLevel,
    required this.oceanDeep,
    required this.oceanMid,
    required this.oceanSurface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate wave parameters
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;
    final radius = math.min(centerX, centerY);

    // Create a shader for the wave gradient
    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        oceanSurface.withOpacity(0.9),
        oceanMid.withOpacity(0.7),
        oceanDeep.withOpacity(0.5),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    // Create paint for the wave
    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Area to fill (from bottom)
    final fillHeight = height * (1.0 - fillLevel);

    // Create the main path for water
    final path = Path();
    path.moveTo(0, height);

    // Wave parameters
    final baseWaveHeight = fillHeight;
    final waveWidth = width;
    final waveHeight = radius * 0.05; // amplitude

    // Draw two overlapping waves for more natural effect
    final primaryWaveSpeed = waveAnimation * math.pi * 2;
    final secondaryWaveSpeed = waveAnimation * math.pi * 3;

    // Higher resolution makes smoother curves
    final step = 2.0; // smaller step = smoother curve

    for (double x = 0; x <= width; x += step) {
      // Calculate wave Y position with two overlapping sine waves
      final primary =
          math.sin((x / waveWidth * 8 * math.pi) + primaryWaveSpeed);
      final secondary =
          math.sin((x / waveWidth * 12 * math.pi) + secondaryWaveSpeed) * 0.3;

      // Wave Y position with dynamic amplitude near the fill level
      final dynamicAmplitude =
          waveHeight * (1.0 - 0.3 * math.cos(primaryWaveSpeed));
      final waveY = baseWaveHeight + (primary + secondary) * dynamicAmplitude;

      // Add point to path
      path.lineTo(x, waveY);
    }

    // Complete the path
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    // Draw the wave, clipped to the circle
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromLTWH(0, 0, width, height));
    canvas.clipPath(clipPath);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.fillLevel != fillLevel;
  }
}
