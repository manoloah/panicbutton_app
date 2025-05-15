import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable SliverAppBar for consistent navigation across the app.
///
/// This widget encapsulates the app's standardized header appearance and behavior
/// while providing customization options for specific screen needs.
class CustomSliverAppBar extends StatelessWidget {
  /// Whether to show a back button in the leading position
  final bool showBackButton;

  /// The route to navigate to when the back button is pressed
  final String? backRoute;

  /// Custom back button callback, overrides default navigation
  final VoidCallback? onBackPressed;

  /// Additional actions to display after the settings button
  final List<Widget>? additionalActions;

  /// Whether to show the settings button
  final bool showSettings;

  /// The title to display in the app bar (optional)
  final Widget? title;

  /// Whether the app bar should remain visible when scrolled
  final bool pinned;

  const CustomSliverAppBar({
    super.key,
    this.showBackButton = false,
    this.backRoute,
    this.onBackPressed,
    this.additionalActions,
    this.showSettings = true,
    this.title,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Determine the leading widget based on showBackButton
    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ??
            () {
              if (backRoute != null) {
                context.go(backRoute!);
              } else {
                Navigator.maybePop(context);
              }
            },
      );
    }

    // Build the actions list
    final List<Widget> actionWidgets = [];

    // Add settings button if requested
    if (showSettings) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.go('/settings'),
        ),
      );
    }

    // Add any additional actions
    if (additionalActions != null) {
      actionWidgets.addAll(additionalActions!);
    }

    return SliverAppBar(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      pinned: pinned,
      floating: true,
      snap: true,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: title,
      centerTitle: false,
      actions: actionWidgets,
    );
  }
}
