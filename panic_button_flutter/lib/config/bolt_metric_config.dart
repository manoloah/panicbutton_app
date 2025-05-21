import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import '../constants/images.dart';

/// BOLT-specific configuration
class BoltMetricConfig {
  /// Get the BOLT metric configuration
  static MetricConfig get config => MetricConfig(
        tableName: 'bolt_scores',
        scoreFieldName: 'score_seconds',
        metricName: 'BOLT',
        screenTitle: 'Mide tu nivel de calma',
        metricDescription:
            'La prueba BOLT mide tu resistencia al CO2 y refleja tu nivel de calma. A mayor puntaje, menor riesgo de ansiedad o ataques de pánico.',
        longDescription:
            'La prueba BOLT (Body Oxygen Level Test) mide tu resistencia al CO2 y refleja tu nivel de calma. A mayor puntaje, menor riesgo de ansiedad o ataques de pánico. Para mejores resultados, realiza esta medición al despertar por la mañana.',
        measurementInstructions:
            'Para mejores resultados, realiza esta medición al despertar por la mañana.',
        startButtonText: 'COMENZAR',
        stopButtonText: 'DETENER',
        instructionImage: Images.breathCalm,
        simplifiedInstructions: [
          '1. Respira normalmente varias veces',
          '2. Pincha tu nariz y retén la respiración',
          '3. Mide hasta sentir la primera falta de aire'
        ],
        instructionSteps: [
          // Step 0: Initial calm breathing
          MetricInstructionStep(
            instructionText: 'Cálmate y respira de forma normal',
            allowManualAdvance: true,
          ),
          // Step 1: Normal inhale
          MetricInstructionStep(
            instructionText: 'Inhala normal',
            duration: const Duration(seconds: 5),
            requiresBreathVisualization: true,
            isInhale: true,
          ),
          // Step 2: Normal exhale
          MetricInstructionStep(
            instructionText: 'Exhala normal',
            duration: const Duration(seconds: 5),
            requiresBreathVisualization: true,
            isInhale: false,
          ),
          // Step 3: Hold breath/pinch nose
          MetricInstructionStep(
            instructionText: 'Pincha tu nariz o retén la respiración',
            allowManualAdvance: true,
            stepImage: Images.pinchNose,
          ),
        ],
        scoreZones: [
          ScoreZone(
            maxValue: 10.0,
            label: '<10 - Pánico Constante',
            description:
                'Vives en un estado constante de alerta, sientes que todo es peligroso aunque no lo sea.',
            color: Colors.redAccent.shade200,
            textColor: Colors.white,
          ),
          ScoreZone(
            maxValue: 15.0,
            label: '10-15 - Ansioso/Inestable',
            description:
                'Todavía te sientes en alerta, pero empiezas a darte cuenta de que no todo es una amenaza.',
            color: Colors.orange,
          ),
          ScoreZone(
            maxValue: 20.0,
            label: '15-20 - Inquieto/Irregular',
            description:
                'Empiezas a relajarte, pero todavía te sientes un poco nervioso o inquieto.',
            color: Colors.amber,
          ),
          ScoreZone(
            maxValue: 25.0,
            label: '20-25 - Calma Parcial',
            description:
                'La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.',
            color: Colors.lightGreen,
          ),
          ScoreZone(
            maxValue: 30.0,
            label: '25-30 - Tranquilo/Estable',
            description:
                'La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.',
            color: Colors.teal.shade300,
          ),
          ScoreZone(
            maxValue: 40.0,
            label: '30-40 - Zen/Inmune',
            description: 'Te sientes tranquilo, seguro y estable.',
            color: Colors.blue.shade300,
          ),
          ScoreZone(
            maxValue: double.infinity,
            label: '40+ - Beyond Zen',
            description:
                'Estás en un estado profundo de calma y control, difícilmente te alteras.',
            color: Colors.indigo.shade300,
          ),
        ],
        formatScore: (score) => '$score segundos',
        buildDetailedInstructions: (context) {
          return [
            _buildInstructionStep(context, 1,
                'Respira de forma tranquila por la nariz unas cuantas veces'),
            _buildInstructionStep(
                context, 2, 'Realiza una inhalación NORMAL durante 5 segundos'),
            _buildInstructionStep(
                context, 3, 'Realiza una exhalación NORMAL durante 5 segundos'),
            _buildInstructionStep(
                context, 4, 'Pincha tu nariz o retén la respiración'),
            _buildInstructionStep(context, 5, 'Inicia el cronómetro'),
            _buildInstructionStep(context, 6,
                'Espera hasta sentir la PRIMERA necesidad de respirar o falta de aire'),
            _buildInstructionStep(
                context, 7, 'Detén el cronometro en ese momento'),
            _buildInstructionStep(context, 8,
                'Regresa a respirar como empezaste de forma normal, lenta y controlada'),
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

  /// Determine mental state color based on score
  static Color getMentalStateColor(int score) {
    if (score <= 10) {
      return const Color(0xFF8D7DAF); // Soft purple
    } else if (score <= 15) {
      return const Color(0xFF7A97C9); // Soft blue-purple
    } else if (score <= 20) {
      return const Color(0xFF68B0C1); // Teal-blue
    } else if (score <= 25) {
      return const Color(0xFF5BBFAD); // Mint green
    } else if (score <= 30) {
      return const Color(0xFF52A375); // More green than teal
    } else if (score <= 40) {
      return const Color(0xFF3B7F8C); // Deep teal
    } else {
      return const Color(0xFF4265D6); // Brighter blue for better contrast
    }
  }

  /// Get mental state description based on score
  static String getMentalStateDescription(int score) {
    if (score <= 10) {
      return 'Vives en un estado constante de alerta, sientes que todo es peligroso aunque no lo sea.';
    } else if (score <= 15) {
      return 'Todavía te sientes en alerta, pero empiezas a darte cuenta de que no todo es una amenaza.';
    } else if (score <= 20) {
      return 'Empiezas a relajarte, pero todavía te sientes un poco nervioso o inquieto.';
    } else if (score <= 30) {
      return 'La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.';
    } else if (score <= 40) {
      return 'Te sientes tranquilo, seguro y estable.';
    } else {
      return 'Estás en un estado profundo de calma y control, difícilmente te alteras.';
    }
  }
}
