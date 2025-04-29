import 'package:flutter/material.dart';

class PhaseIndicator extends StatelessWidget {
  final String phase;
  final int countdown;
  final bool isBreathing;

  const PhaseIndicator({
    super.key,
    required this.phase,
    required this.countdown,
    required this.isBreathing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          phase,
          style: tt.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (isBreathing) ...[
          const SizedBox(height: 8),
          Text(
            countdown.toString(),
            style: tt.displayLarge,
          ),
        ],
      ],
    );
  }
}
