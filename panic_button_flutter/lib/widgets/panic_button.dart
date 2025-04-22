import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class PanicButton extends StatefulWidget {
  const PanicButton({super.key});

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
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
    _controller.forward().then((_) {
      context.push('/breathwork');
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handlePress(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.1),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'EMPEZAR',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          duration: const Duration(seconds: 3),
          color: Colors.white,
        );
  }
}
