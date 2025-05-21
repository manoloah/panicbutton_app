/// Base class for a raw metric score record
class MetricScore {
  final int scoreValue;
  final DateTime createdAt;

  MetricScore({
    required this.scoreValue,
    required this.createdAt,
  });

  factory MetricScore.fromJson(
      Map<String, dynamic> json, String scoreFieldName) {
    return MetricScore(
      scoreValue: json[scoreFieldName] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A period + its average score for chart display
class MetricPeriodScore {
  final DateTime period;
  final double averageScore;

  const MetricPeriodScore({
    required this.period,
    required this.averageScore,
  });
}

/// Enum for different aggregation periods
enum MetricAggregation {
  day,
  week,
  month,
  quarter,
  year;

  String get label {
    switch (this) {
      case MetricAggregation.day:
        return 'Día';
      case MetricAggregation.week:
        return 'Semana';
      case MetricAggregation.month:
        return 'Mes';
      case MetricAggregation.quarter:
        return 'Trimestre';
      case MetricAggregation.year:
        return 'Año';
    }
  }
}
