/// Configuration file that centralizes all app identity information
/// Use this file as the single source of truth for app name, bundle ID, etc.
class AppConfig {
  /// The display name of the app shown on the device home screen
  static const String appDisplayName = "Calme";

  /// The short name used in various contexts
  static const String appName = "Calme";

  /// The app description for stores and SEO
  static const String appDescription =
      "Una aplicación para manejar la ansiedad con ejercicios de respiración";

  /// The bundle ID / application ID
  static const String bundleId = "com.breathmanu.calme";

  /// The company name / organization
  static const String companyName = "breathmanu.com";

  /// The company domain
  static const String companyDomain = "breathmanu.com";

  /// App version - should match the version in pubspec.yaml
  static const String appVersion = "1.0.0";

  /// Build number - should match the build number in pubspec.yaml
  static const String buildNumber = "1";
}
