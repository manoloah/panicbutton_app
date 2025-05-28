import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/metric_score.dart';
import '../models/metric_config.dart';

/// A dedicated widget for displaying score charts with mental state zones
class ScoreChart extends StatelessWidget {
  /// The list of period scores to display
  final List<MetricPeriodScore> periodScores;

  /// Formatter function for bottom axis labels
  final String Function(DateTime) formatBottomLabel;

  /// The metric configuration to use for this chart
  final MetricConfig metricConfig;

  /// Maximum score to display (adjusts Y-axis)
  final double? maxY;

  /// Minimum score to display (adjusts Y-axis)
  final double? minY;

  const ScoreChart({
    super.key,
    required this.periodScores,
    required this.formatBottomLabel,
    required this.metricConfig,
    this.maxY,
    this.minY,
  });

  /// Calculate appropriate Y-axis interval based on metric type and screen size
  double _calculateYAxisInterval(double maxY, bool isSmallScreen) {
    // For MBT (steps), use larger intervals
    if (metricConfig.id == 'mbt') {
      return isSmallScreen ? 30.0 : 20.0; // Show every 30 or 20 steps
    }
    // For BOLT (seconds), use smaller intervals
    else {
      return isSmallScreen ? 20.0 : 10.0; // Show every 20 or 10 seconds
    }
  }

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

    // Get the score zones from the metric config
    final scoreZones = metricConfig.scoreZones;

    // Create a list of mental state boundaries for horizontal lines
    final mentalStateLines = scoreZones
        .map((zone) => {
              'y': zone.upperBound,
              'label': zone.label,
            })
        .toList();

    // Calculate appropriate max/min Y values
    // If not provided, calculate based on data and ensure we show relevant zones
    double maximumScore = periodScores.isEmpty
        ? 0.0
        : periodScores.map((e) => e.averageScore).fold(0.0, math.max);

    double effectiveMaxY = maxY ??
        math.max(
            math.max(
                40.0, // At least show up to 40
                maximumScore * 1.001),
            // Ensure we show at least one zone above the highest data point
            mentalStateLines
                .map((e) => e['y'] as double)
                .where((y) => y > maximumScore)
                .fold(0.0, (a, b) => a == 0 ? b : math.min(a, b)));

    double minimumScore = periodScores.isEmpty
        ? 0.0
        : periodScores
            .map((e) => e.averageScore)
            .fold(double.infinity, math.min);

    double effectiveMinY = minY ??
        math.max(
            0.0,
            math.min(
                5.0, // Default minimum
                minimumScore == double.infinity ? 0.0 : minimumScore * 0.9));

    // On small screens, only show a subset of lines to avoid clutter
    var linesToShow = mentalStateLines;
    if (isSmallScreen && linesToShow.length > 4) {
      // Show fewer lines on mobile, evenly distributed
      final step = (linesToShow.length / 4).ceil();
      linesToShow = linesToShow
          .asMap()
          .entries
          .where((entry) =>
              entry.key % step == 0 || entry.key == linesToShow.length - 1)
          .map((entry) => entry.value)
          .toList();
    }

    // Generate horizontal lines with labels for mental states - BUT without labels now
    final stateLines = linesToShow
        .where((line) =>
            (line['y'] as double) <=
            effectiveMaxY) // Only show applicable lines
        .map((line) => HorizontalLine(
              y: line['y'] as double,
              color: Colors.grey.shade400,
              strokeWidth: 1,
              dashArray: [5, 5],
              // No labels inside chart - they'll go in the legend
              label: null,
            ))
        .toList();

    // Build horizontal range annotations for zones
    final horizontalRangeAnnotations = <HorizontalRangeAnnotation>[];

    // Add zones that are within the visible chart area
    for (int i = 0; i < scoreZones.length; i++) {
      final currentY = scoreZones[i].upperBound;
      final bottomY = i == 0 ? effectiveMinY : scoreZones[i].lowerBound;

      // Only add if zone is at least partially visible
      if (bottomY < effectiveMaxY && currentY > effectiveMinY) {
        // Clamp to visible area
        final clampedBottom = math.max(bottomY, effectiveMinY);
        final clampedTop = math.min(currentY, effectiveMaxY);

        horizontalRangeAnnotations.add(
          HorizontalRangeAnnotation(
            y1: clampedBottom,
            y2: clampedTop,
            color: scoreZones[i].color,
          ),
        );
      }
    }

    // Calculate responsive dimensions
    final chartPadding = isSmallScreen ? 8.0 : 16.0;
    // Calculate fixed height for chart based on screen size
    final chartHeight = isSmallScreen ? 250.0 : 300.0;

    // Determine bottom title interval based on data density
    // More aggressive spacing for daily views with many data points
    int calculateInterval() {
      final int count = periodScores.length;

      // For daily grouping with many points, show much fewer labels
      if (count > 20) {
        return isSmallScreen
            ? math.max(7, (count / 3).ceil())
            : math.max(5, (count / 4).ceil());
      } else if (count > 14) {
        return isSmallScreen
            ? math.max(5, (count / 4).ceil())
            : math.max(4, (count / 5).ceil());
      } else if (count > 7) {
        return isSmallScreen
            ? math.max(3, (count / 5).ceil())
            : math.max(2, (count / 6).ceil());
      } else {
        return isSmallScreen ? math.max(1, (count / 4).ceil()) : 1;
      }
    }

    final bottomInterval = calculateInterval();

    // Create the chart widget
    Widget buildChart() {
      return LineChart(
        LineChartData(
          minY: effectiveMinY,
          maxY: effectiveMaxY,
          clipData: const FlClipData
              .all(), // Ensure content is clipped to chart bounds
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            verticalInterval: 1, // One vertical line per data point
            getDrawingVerticalLine: (value) {
              final i = value.toInt();
              if (i >= 0 && i < periodScores.length) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 0.5,
                  dashArray: [3, 3],
                );
              }
              return const FlLine(strokeWidth: 0);
            },
            horizontalInterval:
                isSmallScreen ? 30 : 20, // Fewer grid lines on mobile
            getDrawingHorizontalLine: (value) {
              // Style regular grid lines
              if (value == effectiveMinY) {
                // This is the x-axis line (bottom of the chart)
                return FlLine(
                  color: Colors.grey.shade600,
                  strokeWidth: 2,
                );
              } else if (mentalStateLines.any((line) => line['y'] == value)) {
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
          // Add mental state boundary lines without labels
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
              tooltipBgColor: cs.surface.withAlpha(179), // ~0.7 opacity
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    // Format with only one decimal place
                    spot.y.toStringAsFixed(1),
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
                interval: _calculateYAxisInterval(effectiveMaxY, isSmallScreen),
                reservedSize: isSmallScreen ? 35 : 40, // More space for labels
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
                // Increased reserved size for bottom titles to make them more visible
                reservedSize: isSmallScreen ? 75 : 60,
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
                    angle: -math.pi /
                        8, // Even less rotation for better readability
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: isSmallScreen ? 25.0 : 20.0, left: 2.0),
                      child: Text(
                        label,
                        style: tt.bodyMedium?.copyWith(
                          // Smaller font for dense layouts
                          fontSize: periodScores.length > 14
                              ? (isSmallScreen ? 10 : 11)
                              : (isSmallScreen ? 11 : 12),
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
                    radius: isSmallScreen ? 4.0 : 3.5, // Larger dots on mobile
                    color: cs.primary,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withAlpha(77), // ~0.3 opacity
              ),
            ),
          ],
        ),
      );
    }

    // Helper method to build a legend item
    Widget buildLegendItem(Color color, String label, TextTheme tt,
        {Color? textColor}) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? 160 : 180, // Constrain width for better fit
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(230), // ~0.9 opacity
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: tt.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Create the legend widget as a two-column grid for better space utilization
    Widget buildLegend() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8), // Follow 8-point grid
        child: GridView.builder(
          shrinkWrap: true, // Important to avoid height issues
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            childAspectRatio: 3.0, // Wider than tall for text items
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: scoreZones.length,
          itemBuilder: (context, index) {
            // First zone (red) with white text for better visibility
            final zone = scoreZones[index];
            final needsWhiteText = index == 0; // Red zone needs white text

            return buildLegendItem(
              zone.color,
              zone.label,
              tt,
              textColor: needsWhiteText ? Colors.white : null,
            );
          },
        ),
      );
    }

    // Use a Column with proper constraints to avoid the RenderFlex overflow
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            chartHeight + (isSmallScreen ? 180 : 200), // Total max height
      ),
      child: Container(
        padding: EdgeInsets.all(chartPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // This is crucial to avoid overflow
          children: [
            // Fixed height chart container
            SizedBox(
              height: chartHeight,
              child: buildChart(),
            ),
            const SizedBox(height: 8), // Follow 8-point grid
            // Legend at the bottom - constrain height to prevent overflow
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 120 : 140, // Limit legend height
                ),
                child: buildLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A period + its average score:
class ScorePeriod {
  final DateTime period;
  final double averageScore;

  const ScorePeriod({
    required this.period,
    required this.averageScore,
  });
}
