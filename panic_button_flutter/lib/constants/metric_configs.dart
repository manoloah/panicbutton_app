import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import '../constants/images.dart';

/// Factory class for creating metric configurations
class MetricConfigs {
  MetricConfigs._(); // Private constructor to prevent instantiation

  /// The BOLT metric configuration
  static final MetricConfig boltConfig = MetricConfig(
    id: 'bolt',
    displayName: 'BOLT',
    tableName: 'bolt_scores',
    shortName: 'BOLT',
    description:
        'La prueba BOLT mide tu resistencia al CO2 y refleja tu nivel de calma. A mayor puntaje, menor riesgo de ansiedad o ataques de pánico.',
    chartTitle: 'Tu progreso',
    resultTitle: 'Tu puntuación: %s segundos',
    scoreFieldName: 'score_seconds',
    recommendationText:
        'Para mejores resultados, realiza esta medición al despertar por la mañana.',

    // Score zones for the chart
    scoreZones: [
      MetricScoreZone(
        lowerBound: 0,
        upperBound: 10,
        label: '<10 - Pánico Constante',
        color: Colors.redAccent.shade200.withAlpha(174),
      ),
      MetricScoreZone(
        lowerBound: 10,
        upperBound: 15,
        label: '10-15 - Ansioso/Inestable',
        color: Colors.orange.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 15,
        upperBound: 20,
        label: '15-20 - Inquieto/Irregular',
        color: Colors.amber.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 20,
        upperBound: 25,
        label: '20-25 - Calma Parcial',
        color: Colors.lightGreen.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 25,
        upperBound: 30,
        label: '25-30 - Tranquilo/Estable',
        color: Colors.teal.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 30,
        upperBound: 40,
        label: '30-40 - Zen/Inmune',
        color: Colors.blue.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 40,
        upperBound: 100, // Large upper bound for "beyond" category
        label: '40+ - Beyond Zen',
        color: Colors.indigo.shade300.withAlpha(80),
      ),
    ],

    // Detailed instruction steps
    detailedInstructions: [
      MetricInstructionStep(
        stepNumber: 1,
        description:
            'Respira de forma tranquila por la nariz unas cuantas veces',
      ),
      MetricInstructionStep(
        stepNumber: 2,
        description: 'Realiza una inhalación NORMAL durante 5 segundos',
        isTimedStep: true,
        durationSeconds: 5,
      ),
      MetricInstructionStep(
        stepNumber: 3,
        description: 'Realiza una exhalación NORMAL durante 5 segundos',
        isTimedStep: true,
        durationSeconds: 5,
      ),
      MetricInstructionStep(
        stepNumber: 4,
        description: 'Pincha tu nariz o retén la respiración',
        imagePath: Images.pinchNose,
      ),
      MetricInstructionStep(
        stepNumber: 5,
        description: 'Inicia el cronómetro',
        icon: Icons.timer,
      ),
      MetricInstructionStep(
        stepNumber: 6,
        description:
            'Espera hasta sentir la PRIMERA necesidad de respirar o falta de aire',
      ),
      MetricInstructionStep(
        stepNumber: 7,
        description: 'Detén el cronometro en ese momento',
      ),
      MetricInstructionStep(
        stepNumber: 8,
        description:
            'Regresa a respirar como empezaste de forma normal, lenta y controlada',
      ),
    ],

    // Compact steps for summary view
    compactSteps: [
      MetricInstructionStep(
        stepNumber: 1,
        description: 'Respira\nNormal',
        icon: Icons.air_rounded,
      ),
      MetricInstructionStep(
        stepNumber: 2,
        description: 'Retén\nrespiración',
        imagePath: Images.pinchNose,
      ),
      MetricInstructionStep(
        stepNumber: 3,
        description: 'Mide\nTiempo',
        icon: Icons.timer,
      ),
    ],

    // Score description function
    getScoreDescription: (int score) {
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
    },

    // Score color function
    getScoreColor: (int score) {
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
    },
  );
}
