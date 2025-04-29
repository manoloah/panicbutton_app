import 'package:flutter/material.dart';

class RemainingTimeDisplay extends StatelessWidget {
  final int totalSeconds;

  const RemainingTimeDisplay({
    super.key,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Text(
      _formatTime(totalSeconds),
      style: tt.displayLarge,
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
