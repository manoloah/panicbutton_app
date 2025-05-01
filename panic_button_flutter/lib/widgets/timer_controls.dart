import 'package:flutter/material.dart';

/// A widget that allows the user to increase or decrease the session duration
class TimerControls extends StatelessWidget {
  final int totalSeconds;
  final Function(int) onTimeChanged;
  final bool enabled;

  const TimerControls({
    Key? key,
    required this.totalSeconds,
    required this.onTimeChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int minutes = totalSeconds ~/ 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          IconButton(
            onPressed: enabled ? () => _decreaseTime(minutes) : null,
            icon: Icon(
              Icons.remove_circle_outline,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 24,
            ),
          ),

          // Time display
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            alignment: Alignment.center,
            child: Text(
              '$minutes min',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                  ),
            ),
          ),

          // Increase button
          IconButton(
            onPressed: enabled ? () => _increaseTime(minutes) : null,
            icon: Icon(
              Icons.add_circle_outline,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _decreaseTime(int currentMinutes) {
    // Don't allow less than 1 minute
    if (currentMinutes <= 1) return;

    final int newSeconds = (currentMinutes - 1) * 60;
    onTimeChanged(newSeconds);
  }

  void _increaseTime(int currentMinutes) {
    // Cap at 30 minutes
    if (currentMinutes >= 30) return;

    final int newSeconds = (currentMinutes + 1) * 60;
    onTimeChanged(newSeconds);
  }
}
