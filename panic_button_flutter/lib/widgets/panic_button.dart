import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PanicButton extends StatefulWidget {
  const PanicButton({super.key});

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heartbeatAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller with a longer duration for the heartbeat
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create a heartbeat animation sequence
    _heartbeatAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    // Start the heartbeat animation and repeat it
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    setState(() {
      _isPressed = true;
    });

    // Navigate directly to the coherent_4_6 pattern
    // Pass fromHome flag to indicate we're coming from the home screen
    context.go('/breath/coherent_4_6', extra: {'fromHome': true});

    // Reset the button state after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Adapt button size based on screen size
    final screenSize = MediaQuery.of(context).size;
    // Calculate button size based on screen width (smaller on smaller screens)
    // Make button smaller on iPhone SE and other small devices
    final buttonSize = screenSize.width < 360
        ? 160.0
        : screenSize.width < 400
            ? 180.0
            : 200.0;

    return GestureDetector(
      onTapDown: (_) => _handlePress(),
      child: AnimatedBuilder(
        animation: _heartbeatAnimation,
        builder: (context, child) {
          // Scale based on both the heartbeat animation and the press state
          final pressScale = _isPressed ? 0.9 : 1.0;
          final finalScale = _heartbeatAnimation.value * pressScale;

          return Transform.scale(
            scale: finalScale,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'EMPEZAR',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: screenSize.width < 360 ? 24 : 28,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
