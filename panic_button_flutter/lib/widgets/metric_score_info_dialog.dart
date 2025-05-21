import 'package:flutter/material.dart';
import '../models/metric_config.dart';

/// Dialog that shows information about what different score ranges mean
class MetricScoreInfoDialog extends StatelessWidget {
  /// The metric configuration to use
  final MetricConfig metricConfig;

  const MetricScoreInfoDialog({
    super.key,
    required this.metricConfig,
  });

  /// Show the dialog from any context
  static Future<void> show(BuildContext context, MetricConfig metricConfig) {
    return showDialog(
      context: context,
      builder: (context) => MetricScoreInfoDialog(metricConfig: metricConfig),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final scrollController = ScrollController();

    // Helper method to create a row for the score table
    TableRow _buildScoreTableRow(
      ColorScheme cs,
      TextTheme tt,
      String range,
      String description,
      Color color,
    ) {
      return TableRow(
        children: [
          // Score range cell
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: color.withAlpha((0.6 * 255).toInt()), width: 1.5),
              ),
              child: Text(
                range,
                style: tt.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Description cell
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Text(
              description,
              style: tt.bodyMedium,
            ),
          ),
        ],
      );
    }

    // Create table rows from the score zones
    List<TableRow> buildScoreTableRows() {
      final rows = <TableRow>[];

      for (int i = 0; i < metricConfig.scoreZones.length; i++) {
        final zone = metricConfig.scoreZones[i];

        // Determine the range text
        final lowerBound = zone.lowerBound.toInt();
        final upperBound = i == metricConfig.scoreZones.length - 1
            ? '∞' // Last zone has no upper limit
            : zone.upperBound.toInt().toString();

        final rangeText = '$lowerBound-$upperBound segs';

        // Get the description dynamically
        final midPoint = ((zone.upperBound + zone.lowerBound) / 2).toInt();
        final description = metricConfig.getScoreDescription(midPoint);

        // Get color for this zone
        final color = metricConfig.getScoreColor(midPoint);

        rows.add(_buildScoreTableRow(cs, tt, rangeText, description, color));
      }

      return rows;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom title bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '¿Qué significa tu score?',
                      style: tt.headlineSmall?.copyWith(
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Table(
                        columnWidths: const {
                          0: FixedColumnWidth(
                              80), // Fixed width for score range column
                          1: FlexColumnWidth(), // Flexible width for description column
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: buildScoreTableRows(),
                      ),
                      // Add padding at the bottom to ensure the last item is fully visible
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            // Scroll indicator at the bottom
            Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.surface.withAlpha((0 * 255).toInt()),
                    cs.surface,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
                ),
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
