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

    return Stack(
      children: [
        Positioned.fill(
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
        ),
      ],
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

  // Cache values for smooth transitions
  static double _lastFillLevel = 0.5;
  // Reduce calculation frequency with step size
  static const double _stepSize =
      1.5; // Increase step size for better performance

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

    // Smooth transition between fill levels (interpolation to avoid jerky movement)
    // Using a stronger interpolation factor for smoother changes
    _lastFillLevel = _lastFillLevel * 0.9 + fillLevel * 0.1;
    final smoothFillLevel = _lastFillLevel;

    // Create a shader for the wave gradient with fewer colors for better performance
    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        oceanSurface.withOpacity(0.95),
        oceanMid.withOpacity(0.75),
        oceanDeep.withOpacity(0.55),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    // Create paint for the wave
    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // When fillLevel is near 0, place the wave below the visible area
    final fillHeight = smoothFillLevel <= 0.05
        ? height * 1.1 // Just below the visible area for smoother transition
        : height * (1.0 - smoothFillLevel);

    // Create the main path for water
    final path = Path();
    path.moveTo(0, height);

    // Wave parameters - more simplified for better performance
    // Dynamic wave height based on the fill level - smaller waves at extreme fill levels
    final fillFactor = 4.0 * smoothFillLevel * (1.0 - smoothFillLevel);
    final waveHeight = radius * 0.06 * math.max(0.4, fillFactor);

    // Create simpler wave pattern with fewer components
    final primaryWaveSpeed = waveAnimation * math.pi * 2;
    final secondaryWaveSpeed = waveAnimation * math.pi * 1.3;

    // Pre-calculate wave frequencies for performance
    final baseWaveFreq = 3.5 * math.pi;
    final secondWaveFreq = 5.5 * math.pi;

    // Use larger step size for better performance
    for (double x = 0; x <= width; x += _stepSize) {
      // Calculate wave Y position with simplified wave pattern (fewer components)
      final primary = math.sin((x / width * baseWaveFreq) + primaryWaveSpeed);
      final secondary =
          math.sin((x / width * secondWaveFreq) + secondaryWaveSpeed) * 0.3;

      // Combine waves with minimal randomness
      final combinedWave = primary + secondary;

      // Dynamic amplitude that changes less frequently
      final dynamicAmplitude =
          waveHeight * (1.0 + 0.1 * math.sin(primaryWaveSpeed));

      // Final wave Y position with simplified calculations
      final waveY = fillHeight + combinedWave * dynamicAmplitude;

      // Add point to path (simplified)
      if (x == 0) {
        path.moveTo(x, waveY);
      } else {
        path.lineTo(x, waveY);
      }
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
        (oldDelegate.fillLevel - fillLevel).abs() >
            0.005; // Less sensitive repainting
  }
}
