import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// A dedicated widget for displaying BOLT scores chart with mental state zones
class BoltChart extends StatelessWidget {
  /// The list of period scores to display
  final List<PeriodScore> periodScores;

  /// Formatter function for bottom axis labels
  final String Function(DateTime) formatBottomLabel;

  /// Maximum score to display (adjusts Y-axis)
  final double? maxY;

  /// Minimum score to display (adjusts Y-axis)
  final double? minY;

  const BoltChart({
    super.key,
    required this.periodScores,
    required this.formatBottomLabel,
    this.maxY,
    this.minY,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400; // Increased threshold

    if (periodScores.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos suficientes para mostrar una gráfica',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Define zone boundaries and labels
    final mentalStateLines = [
      {'y': 10.0, 'label': 'Pánico Constante'},
      {'y': 15.0, 'label': 'Ansioso/Inestable'},
      {'y': 20.0, 'label': 'Inquieto/Irregular'},
      {'y': 25.0, 'label': 'Calma Parcial'},
      {'y': 30.0, 'label': 'Tranquilo/Estable'},
      {'y': 40.0, 'label': 'Zen/Inmune'},
    ];

    // Zone colors for different mental states
    final zoneColors = [
      Colors.redAccent.shade200, // < 10: Pánico Constante
      Colors.orange, // 10-15: Ansioso/Inestable
      Colors.amber, // 15-20: Inquieto/Irregular
      Colors.lightGreen, // 20-25: Calma Parcial
      Colors.teal.shade300, // 25-30: Tranquilo/Estable
      Colors.blue.shade300, // 30-35: Zen/Inmune
      Colors.indigo.shade300, // 35+: Beyond Zen
    ];

    // Calculate appropriate max/min Y values
    // If not provided, calculate based on data and ensure we show relevant zones
    double effectiveMaxY = maxY ??
        math.max(
            math.max(
                40.0, // At least show up to 40
                periodScores.map((e) => e.averageScore).fold(0.0, math.max) *
                    1.1),
            // Ensure we show at least one zone above the highest data point
            mentalStateLines
                .map((e) => e['y'] as double)
                .where((y) =>
                    y >
                    periodScores.map((e) => e.averageScore).fold(0.0, math.max))
                .fold(0.0, (a, b) => a == 0 ? b : math.min(a, b)));

    double effectiveMinY = minY ??
        math.max(
            0.0,
            math.min(
                5.0, // Default minimum
                periodScores
                        .map((e) => e.averageScore)
                        .fold(double.infinity, math.min) *
                    0.9));

    // On small screens, only show a subset of lines to avoid clutter
    var linesToShow = mentalStateLines;
    if (isSmallScreen) {
      // Show fewer lines on mobile: 10, 20, 30, 35
      linesToShow = mentalStateLines.where((line) {
        final y = line['y'] as double;
        return y == 10.0 || y == 20.0 || y == 30.0 || y == 35.0;
      }).toList();
    }

    // Generate horizontal lines with labels for mental states
    final stateLines = linesToShow
        .where((line) =>
            (line['y'] as double) <=
            effectiveMaxY) // Only show applicable lines
        .map((line) => HorizontalLine(
              y: line['y'] as double,
              color: Colors.grey.shade400,
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: EdgeInsets.only(
                    right: isSmallScreen ? 8 : 12,
                    bottom: isSmallScreen ? 1 : 2),
                style: TextStyle(
                  color: zoneColors[mentalStateLines.indexOf(line)],
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 10 : 11,
                ),
                labelResolver: (line) {
                  // Get the index of this mental state
                  final index =
                      mentalStateLines.indexWhere((l) => l['y'] == line.y);
                  final label = mentalStateLines[index]['label'] as String;

                  // On small screens, show more compact labels
                  if (isSmallScreen) {
                    return "${line.y.toInt()} - $label";
                  }
                  return "${line.y.toInt()} - $label";
                },
              ),
            ))
        .toList();

    // Build horizontal range annotations for zones
    final horizontalRangeAnnotations = <HorizontalRangeAnnotation>[];

    // Add zones that are within the visible chart area
    for (int i = 0; i < mentalStateLines.length; i++) {
      final currentY = mentalStateLines[i]['y'] as double;

      // Determine bottom of zone
      final double bottomY =
          i == 0 ? effectiveMinY : (mentalStateLines[i - 1]['y'] as double);

      // Only add if zone is at least partially visible
      if (bottomY < effectiveMaxY && currentY > effectiveMinY) {
        // Clamp to visible area
        final clampedBottom = math.max(bottomY, effectiveMinY);
        final clampedTop = math.min(currentY, effectiveMaxY);

        horizontalRangeAnnotations.add(
          HorizontalRangeAnnotation(
            y1: clampedBottom,
            y2: clampedTop,
            color: zoneColors[i].withAlpha((zoneColors[i].alpha * 255).toInt()),
          ),
        );
      }
    }

    // Add the highest zone if needed
    if (mentalStateLines.last['y'] as double < effectiveMaxY) {
      horizontalRangeAnnotations.add(
        HorizontalRangeAnnotation(
          y1: mentalStateLines.last['y'] as double,
          y2: effectiveMaxY,
          color:
              zoneColors.last.withAlpha((zoneColors.last.alpha * 255).toInt()),
        ),
      );
    }

    // Calculate responsive dimensions
    final chartPadding = isSmallScreen ? 8.0 : 16.0;
    // Use a smaller aspect ratio on small screens to make chart taller
    final aspectRatio = isSmallScreen ? 1.0 : 1.7;

    // Determine bottom title interval based on data density
    final bottomInterval = isSmallScreen
        ? math.max(
            1,
            (periodScores.length / 4)
                .ceil()) // Show at most 4 labels on small screens
        : 1;

    return Container(
      padding: EdgeInsets.all(chartPadding),
      // Use a fixed minimum height on small screens to ensure visibility
      constraints: isSmallScreen
          ? const BoxConstraints(minHeight: 300)
          : const BoxConstraints(),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LineChart(
          LineChartData(
            minY: effectiveMinY,
            maxY: effectiveMaxY,
            clipData: const FlClipData
                .all(), // Ensure content is clipped to chart bounds
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval:
                  isSmallScreen ? 10 : 5, // Fewer grid lines on mobile
              getDrawingHorizontalLine: (value) {
                // Style regular grid lines
                if (mentalStateLines.any((line) => line['y'] == value)) {
                  // This is a mental state boundary - use dotted line
                  return FlLine(
                    color: Colors.grey.shade400,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                }
                // Regular grid line
                return FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 0.5,
                );
              },
            ),
            // Add mental state boundary lines with labels
            extraLinesData: ExtraLinesData(
              horizontalLines: stateLines,
            ),
            // Add zone backgrounds
            rangeAnnotations: RangeAnnotations(
              verticalRangeAnnotations: [],
              horizontalRangeAnnotations: horizontalRangeAnnotations,
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor:
                    cs.surface.withAlpha((cs.surface.alpha * 255).toInt()),
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      // Format with only one decimal place
                      '${spot.y.toStringAsFixed(1)}',
                      TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            isSmallScreen ? 14 : 14, // Larger font on mobile
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: isSmallScreen ? 10 : 5, // Fewer labels on mobile
                  reservedSize:
                      isSmallScreen ? 35 : 40, // More space for labels
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: tt.bodyMedium?.copyWith(
                      fontSize:
                          isSmallScreen ? 12 : null, // Larger font on mobile
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: bottomInterval.toDouble(),
                  reservedSize:
                      isSmallScreen ? 40 : 30, // More space for rotated labels
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= periodScores.length) {
                      return const SizedBox.shrink();
                    }

                    // On small screens, only show selected labels to avoid overlap
                    if (isSmallScreen && i % bottomInterval != 0) {
                      return const SizedBox.shrink();
                    }

                    final label = formatBottomLabel(periodScores[i].period);
                    return Transform.rotate(
                      angle: isSmallScreen ? -math.pi / 4 : -math.pi / 4,
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: isSmallScreen ? 8.0 : 0),
                        child: Text(
                          label,
                          style: tt.bodyMedium?.copyWith(
                            fontSize: isSmallScreen ? 11 : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: periodScores
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.averageScore))
                    .toList(),
                isCurved: true,
                color: cs.primary,
                barWidth:
                    isSmallScreen ? 3 : 3, // Slightly thicker line on mobile
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius:
                          isSmallScreen ? 4.0 : 3.5, // Larger dots on mobile
                      color: cs.primary,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: cs.primary.withAlpha((cs.primary.alpha * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A period + its average score:
class PeriodScore {
  final DateTime period;
  final double averageScore;

  const PeriodScore({
    required this.period,
    required this.averageScore,
  });
}
