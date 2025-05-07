import 'dart:convert';

/// Represents a level in the breathing journey that users can unlock
class JourneyLevel {
  /// Unique identifier for the level (1-12)
  final int id;

  /// Level name in Spanish
  final String nameEs;

  /// Minimum BOLT score required to unlock this level
  final int boltMin;

  /// Minimum minutes of practice per week required to unlock this level
  final int minutesWeek;

  /// List of breathing pattern slugs that are unlocked at this level
  final List<String> patternSlugs;

  /// Description of the breathing exercise in Spanish
  final String descriptionEs;

  /// Benefits of the breathing exercise in Spanish
  final String benefitEs;

  const JourneyLevel({
    required this.id,
    required this.nameEs,
    required this.boltMin,
    required this.minutesWeek,
    required this.patternSlugs,
    required this.descriptionEs,
    required this.benefitEs,
  });

  /// Factory constructor to create a JourneyLevel from JSON
  factory JourneyLevel.fromJson(Map<String, dynamic> json) {
    return JourneyLevel(
      id: json['id'] as int,
      nameEs: json['name_es'] as String,
      boltMin: json['bolt_min'] as int,
      minutesWeek: json['minutes_week'] as int,
      patternSlugs: List<String>.from(json['pattern_slugs'] as List),
      descriptionEs: json['description_es'] as String,
      benefitEs: json['benefit_es'] as String,
    );
  }

  /// Convert JourneyLevel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_es': nameEs,
      'bolt_min': boltMin,
      'minutes_week': minutesWeek,
      'pattern_slugs': patternSlugs,
      'description_es': descriptionEs,
      'benefit_es': benefitEs,
    };
  }

  @override
  String toString() {
    return 'JourneyLevel{id: $id, nameEs: $nameEs, boltMin: $boltMin, minutesWeek: $minutesWeek}';
  }
}

/// Utility to parse a list of journey levels from JSON
List<JourneyLevel> parseJourneyLevels(String jsonString) {
  final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData
      .map((levelJson) =>
          JourneyLevel.fromJson(levelJson as Map<String, dynamic>))
      .toList();
}
