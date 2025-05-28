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
        'La prueba BOLT mide tu resistencia al CO2 en reposo y refleja tu nivel de calma en ese momento. A mayor puntaje, menor riesgo de ataques.',
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
        label: '<10: Pánico Constante',
        color: Colors.redAccent.shade200.withAlpha(174),
      ),
      MetricScoreZone(
        lowerBound: 10,
        upperBound: 15,
        label: '10-15: Ansiedad Inestable',
        color: Colors.orange.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 15,
        upperBound: 20,
        label: '15-20: Inquietud Irregular',
        color: Colors.amber.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 20,
        upperBound: 30,
        label: '20-30: Calma Parcial',
        color: Colors.lightGreen.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 30,
        upperBound: 40,
        label: '30-40: Tranquilidad Estable',
        color: Colors.teal.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 40,
        upperBound: 50,
        label: '40-50: Inmune al estrés',
        color: Colors.blue.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 50,
        upperBound: 60, // Large upper bound for "beyond" category
        label: '50-60: Zen',
        color: Colors.indigo.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 60,
        upperBound: 70,
        label: '60+: Beyond Zen',
        color: Colors.indigo.shade500.withAlpha(80),
      ),
    ],

    // Enhanced instruction steps based on CSV data
    enhancedInstructions: [
      EnhancedInstructionStep(
        stepNumber: 1,
        mainText: 'Respira por la nariz con calma',
        supportText: 'En reposo, sientate o acuestate',
        callToActionText: 'Comenzar',
        icon: Icons.air_rounded,
        movesToNextStepAutomatically: false,
        nextStepPrepText: 'Preparate para inhalar',
      ),
      EnhancedInstructionStep(
        stepNumber: 2,
        mainText: 'Inhala de forma normal',
        supportText: 'Por la nariz',
        callToActionText: '',
        icon: Icons.air_rounded,
        movesToNextStepAutomatically: true,
        nextStepPrepText: 'Preparate para exhalar',
        isTimedStep: true,
        durationSeconds: 5,
      ),
      EnhancedInstructionStep(
        stepNumber: 3,
        mainText: 'Exhala de forma normal',
        supportText: 'Por la nariz',
        callToActionText: '',
        icon: Icons.air_rounded,
        movesToNextStepAutomatically: true,
        nextStepPrepText: 'Preparate para retener',
        isTimedStep: true,
        durationSeconds: 5,
      ),
      EnhancedInstructionStep(
        stepNumber: 4,
        mainText: 'Pincha tu nariz',
        supportText: 'Y reten el aire',
        callToActionText: 'Empezar cronómetro',
        imagePath: Images.pinchNose,
        movesToNextStepAutomatically: false,
        nextStepPrepText: 'Retén hasta la primer sensación de falta de aire',
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
      } else if (score <= 50) {
        return 'Estás en un estado profundo de calma y control, difícilmente te alteras.';
      } else if (score <= 60) {
        return 'Estado de tranquilidad total, claridad mental y resistencia al estrés máxima.';
      } else {
        return 'Tu control de estrés es óptimo, de elite.';
      }
    },

    // Score color function
    getScoreColor: (int score) {
      if (score <= 10) {
        return Colors.redAccent.shade200.withAlpha(120); // Red 5%
      } else if (score <= 15) {
        return Colors.orange.withAlpha(120); // Orange 5%
      } else if (score <= 20) {
        return Colors.amber.withAlpha(120); // Amber 80%
      } else if (score <= 30) {
        return Colors.lightGreen.withAlpha(120); // Mint green
      } else if (score <= 40) {
        return Colors.teal.shade300.withAlpha(120); // More green than teal
      } else if (score <= 50) {
        return Colors.blue.shade300.withAlpha(120); // Deep Blue
      } else if (score <= 60) {
        return Colors.indigo.shade300.withAlpha(120); // Indigo 5%
      } else {
        return Colors.indigo.shade500.withAlpha(120); // Indigo 5%
      }
    },
  );

  /// The MBT metric configuration
  static final MetricConfig mbtConfig = MetricConfig(
    id: 'mbt',
    displayName: 'MBT',
    tableName: 'mbt_scores',
    shortName: 'MBT',
    description:
        'La prueba MBT mide tu resistencia al CO2 en movimiento y refleja tu nivel de calma a largo plazo. A mayor pasos, menor riesgo de ataques.',
    chartTitle: 'Tu progreso',
    resultTitle: 'Tu puntuación: %s pasos',
    scoreFieldName: 'steps',
    recommendationText:
        'Realiza esta prueba cuando te sientas descansado y en un lugar seguro para caminar.',

    // Score zones for the chart for MBT
    scoreZones: [
      MetricScoreZone(
        lowerBound: 0,
        upperBound: 20,
        label: '<20: Pánico Constante',
        color: Colors.redAccent.shade200.withAlpha(174),
      ),
      MetricScoreZone(
        lowerBound: 20,
        upperBound: 40,
        label: '20-40: Ansiedad Inestable',
        color: Colors.orange.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 40,
        upperBound: 50,
        label: '40-50: Inquietud Irregular',
        color: Colors.amber.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 50,
        upperBound: 60,
        label: '50-60: Calma Parcial',
        color: Colors.lightGreen.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 60,
        upperBound: 80,
        label: '60-80: Tranquilidad Estable ',
        color: Colors.teal.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 80,
        upperBound: 100,
        label: '80-100: Inmune al estrés',
        color: Colors.blue.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 100,
        upperBound: 130,
        label: '100-130: Zen',
        color: Colors.indigo.shade300.withAlpha(80),
      ),
      MetricScoreZone(
        lowerBound: 130,
        upperBound: 140,
        label: '130+: Beyond Zen',
        color: Colors.indigo.shade500.withAlpha(80),
      ),
    ],

    // Enhanced instruction steps for MBT
    enhancedInstructions: [
      EnhancedInstructionStep(
        stepNumber: 1,
        mainText: 'Respira por la nariz con calma',
        supportText: 'Parado en un espacio amplio para caminar',
        callToActionText: 'Comenzar',
        icon: Icons.air_rounded,
        movesToNextStepAutomatically: false,
        nextStepPrepText: 'Preparate para inhalar',
      ),
      EnhancedInstructionStep(
        stepNumber: 2,
        mainText: 'Inhala de forma normal',
        supportText: 'Por la nariz',
        callToActionText: '',
        icon: Icons.air_rounded,
        movesToNextStepAutomatically: true,
        nextStepPrepText: 'Preparate para exhalar',
        isTimedStep: true,
        durationSeconds: 5,
      ),
      EnhancedInstructionStep(
        stepNumber: 3,
        mainText: 'Exhala de forma normal por la nariz',
        supportText: 'Por la nariz',
        callToActionText: '',
        icon: Icons.air_rounded,
        movesToNextStepAutomatically: true,
        nextStepPrepText: 'Preparate para retener',
        isTimedStep: true,
        durationSeconds: 5,
      ),
      EnhancedInstructionStep(
        stepNumber: 4,
        mainText: 'Pincha tu nariz',
        supportText: 'Y reten el aire',
        callToActionText: 'A caminar',
        imagePath: Images.pinchNose,
        movesToNextStepAutomatically: false,
        nextStepPrepText: 'Empieza a caminar contando pasos',
      ),
      EnhancedInstructionStep(
        stepNumber: 5,
        mainText: 'Empieza a caminar',
        supportText: 'Contando tus pasos',
        callToActionText: 'Registrar pasos',
        icon: Icons.directions_walk,
        movesToNextStepAutomatically: false,
        nextStepPrepText: 'Retén hasta el maximo',
      ),
    ],

    // Compact steps for summary view MBT
    compactSteps: [
      MetricInstructionStep(
        stepNumber: 1,
        description: 'Retén\nrespiración',
        imagePath: Images.pinchNose,
      ),
      MetricInstructionStep(
        stepNumber: 2,
        description: 'Camina\ncontando',
        icon: Icons.directions_walk,
      ),
      MetricInstructionStep(
        stepNumber: 3,
        description: 'Selecciona\npasos',
        icon: Icons.edit,
      ),
    ],

    // Score description function MBT
    getScoreDescription: (int score) {
      if (score <= 20) {
        return 'Vives en un estado constante de alerta, sientes que todo es peligroso aunque no lo sea.';
      } else if (score <= 40) {
        return 'Todavía te sientes en alerta, pero empiezas a darte cuenta de que no todo es una amenaza.';
      } else if (score <= 50) {
        return 'Empiezas a relajarte, pero todavía te sientes un poco nervioso o inquieto.';
      } else if (score <= 60) {
        return 'La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.';
      } else if (score <= 80) {
        return 'Te sientes tranquilo, seguro y estable.';
      } else if (score <= 100) {
        return 'Estás en un estado profundo de calma y control, difícilmente te alteras.';
      } else if (score <= 130) {
        return 'Estado de tranquilidad total, claridad mental y resistencia al estrés máxima.';
      } else {
        return 'Tu control de estrés es óptimo, de elite.';
      }
    },

    // Score color function for MBT
    getScoreColor: (int score) {
      if (score <= 20) {
        return Colors.redAccent.shade200.withAlpha(120); // Red 5%
      } else if (score <= 40) {
        return Colors.orange.withAlpha(120); // Orange 5%
      } else if (score <= 50) {
        return Colors.amber.withAlpha(120); // Amber 80%
      } else if (score <= 60) {
        return Colors.lightGreen.withAlpha(120); // Mint green
      } else if (score <= 80) {
        return Colors.teal.shade300.withAlpha(120); // More green than teal
      } else if (score <= 100) {
        return Colors.blue.shade300.withAlpha(120); // Deep Blue
      } else if (score <= 130) {
        return Colors.indigo.shade300.withAlpha(120);
      } else {
        return Colors.indigo.shade500.withAlpha(120); // Indigo 5%
      }
    },
  );
}
