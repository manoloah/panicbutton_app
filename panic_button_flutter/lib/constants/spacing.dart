/// Spacing constants following the 8-point grid system
/// All measurements should be multiples of 8 (or 4 in certain cases)
class Spacing {
  /// Extra small spacing (4px)
  static const double xs = 4;

  /// Small spacing (8px)
  static const double s = 8;

  /// Medium spacing (16px)
  static const double m = 16;

  /// Large spacing (24px)
  static const double l = 24;

  /// Extra large spacing (32px)
  static const double xl = 32;

  /// 2X large spacing (40px)
  static const double xxl = 40;

  /// 3X large spacing (48px)
  static const double xxxl = 48;

  /// 4X large spacing (56px)
  static const double xxxxl = 56;

  /// 5X large spacing (64px)
  static const double xxxxxl = 64;
}

/// Component-specific spacing constants
class ComponentSpacing {
  /// List item height (48px minimum for touch targets)
  static const double listItemHeight = 48;

  /// List item padding
  static const double listItemPadding = Spacing.m;

  /// Card padding
  static const double cardPadding = Spacing.l;

  /// Screen edge padding
  static const double screenPadding = Spacing.m;

  /// Button height
  static const double buttonHeight = 48;

  /// Button padding horizontal
  static const double buttonPaddingHorizontal = Spacing.l;

  /// Button padding vertical
  static const double buttonPaddingVertical = Spacing.m;

  /// Icon size small
  static const double iconSmall = 16;

  /// Icon size medium
  static const double iconMedium = 24;

  /// Icon size large
  static const double iconLarge = 32;
}
