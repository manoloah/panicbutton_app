import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import '../constants/images.dart';

/// MBT (Maximum Breath Time) specific configuration
class MbtMetricConfig {
  /// Get the MBT metric configuration
  static MetricConfig get config => MetricConfig(
        tableName: 'mbt_scores',
        metricName: 'MBT',
        metricDescription:
            'La prueba MBT (Maximum Breath Time) mide tu capacidad pulmonar y resistencia. A mayor puntaje, mayor capacidad y control respiratorio.',
        longDescription:
            'La prueba MBT (Maximum Breath Time) mide el tiempo máximo que puedes retener la respiración después de una inhalación profunda. Esto refleja tu capacidad pulmonar, resistencia y control respiratorio. Para mejores resultados, realiza esta medición después de un breve calentamiento respiratorio.',
        measurementInstructions:
            'Para mejores resultados, realiza esta medición después de un breve calentamiento respiratorio.',
        startButtonText: 'COMENZAR',
        stopButtonText: 'DETENER',
        instructionImage: Images.breathCalm,
        instructionSteps: [
          // Step 0: Initial calm breathing
          MetricInstructionStep(
            instructionText: 'Cálmate y respira de forma normal',
            allowManualAdvance: true,
          ),
          // Step 1: Deep inhale
          MetricInstructionStep(
            instructionText: 'Inhala profundamente',
            duration: const Duration(seconds: 8),
            requiresBreathVisualization: true,
            isInhale: true,
          ),
          // Step 2: Hold breath
          MetricInstructionStep(
            instructionText: 'Retén el aire (pincha tu nariz si es necesario)',
            allowManualAdvance: true,
            stepImage: Images.pinchNose,
          ),
        ],
        scoreZones: [
          ScoreZone(
            maxValue: 30.0,
            label: '<30 - Capacidad Limitada',
            description:
                'Tu capacidad pulmonar es limitada. Esto puede estar afectando tu resistencia general y nivel de energía.',
            color: Colors.redAccent.shade200,
            textColor: Colors.white,
          ),
          ScoreZone(
            maxValue: 60.0,
            label: '30-60 - Básico',
            description:
                'Tienes una capacidad pulmonar básica. Puedes mejorarla con práctica regular.',
            color: Colors.orange,
          ),
          ScoreZone(
            maxValue: 90.0,
            label: '60-90 - Intermedio',
            description:
                'Tu capacidad pulmonar está en un nivel intermedio. Estás desarrollando buen control respiratorio.',
            color: Colors.amber,
          ),
          ScoreZone(
            maxValue: 120.0,
            label: '90-120 - Avanzado',
            description:
                'Tienes una capacidad pulmonar avanzada y buen control respiratorio.',
            color: Colors.lightGreen,
          ),
          ScoreZone(
            maxValue: 180.0,
            label: '120-180 - Experto',
            description:
                'Tu capacidad pulmonar y control respiratorio están a nivel experto.',
            color: Colors.teal.shade300,
          ),
          ScoreZone(
            maxValue: double.infinity,
            label: '180+ - Maestro',
            description:
                'Tienes una capacidad pulmonar extraordinaria y control respiratorio a nivel de maestro.',
            color: Colors.blue.shade300,
          ),
        ],
        formatScore: (score) => '$score segundos',
        buildDetailedInstructions: (context) {
          return [
            _buildInstructionStep(
                context, 1, 'Respira tranquilamente durante 1-2 minutos'),
            _buildInstructionStep(context, 2,
                'Realiza 3-4 respiraciones completas (inhala y exhala profundamente)'),
            _buildInstructionStep(context, 3,
                'En la última respiración, inhala lo más profundamente posible durante 8 segundos'),
            _buildInstructionStep(context, 4,
                'Retén la respiración el mayor tiempo posible (puedes pinchar tu nariz)'),
            _buildInstructionStep(context, 5, 'Inicia el cronómetro'),
            _buildInstructionStep(context, 6,
                'Cuando ya no puedas retener más la respiración, exhala y detiene el cronómetro'),
            _buildInstructionStep(context, 7,
                'Regresa a respirar de forma normal, lenta y controlada'),
          ];
        },
      );

  /// Helper method to build instruction steps for the detailed instructions
  static Widget _buildInstructionStep(
      BuildContext context, int step, String text) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: tt.bodySmall?.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
