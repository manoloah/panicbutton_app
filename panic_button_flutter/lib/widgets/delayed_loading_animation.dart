import 'dart:async';
import 'package:flutter/material.dart';
import 'package:panic_button_flutter/widgets/breathing_loading_animation.dart';

/// A widget that shows a loading animation only if loading takes longer than
/// a specified delay. This prevents brief loading flashes.
class DelayedLoadingAnimation extends StatefulWidget {
  /// The loading text to display
  final String loadingText;

  /// Whether to show a quote
  final bool showQuote;

  /// The delay before showing the loading animation (milliseconds)
  final int delayMilliseconds;

  /// Widget to show while waiting for the delay and loading completes quickly
  final Widget? placeholder;

  const DelayedLoadingAnimation({
    Key? key,
    this.loadingText = 'Cargando...',
    this.showQuote = true,
    this.delayMilliseconds = 300,
    this.placeholder,
  }) : super(key: key);

  @override
  State<DelayedLoadingAnimation> createState() =>
      _DelayedLoadingAnimationState();
}

class _DelayedLoadingAnimationState extends State<DelayedLoadingAnimation> {
  bool _showLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.delayMilliseconds), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoading) {
      return widget.placeholder ?? const SizedBox();
    }

    return BreathingLoadingAnimation(
      loadingText: widget.loadingText,
      showQuote: widget.showQuote,
    );
  }
}
