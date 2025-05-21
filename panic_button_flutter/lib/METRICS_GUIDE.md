# Métricas de Respiración - Guía de Implementación

Esta guía explica cómo crear nuevas métricas de respiración/estrés usando la arquitectura genérica de métricas de la aplicación.

## Arquitectura General

El sistema de métricas está diseñado para ser completamente configurable y replicable, permitiendo añadir nuevas métricas con facilidad. Consta de los siguientes componentes:

1. **MetricConfig** - Modelo base para la configuración de métricas
2. **MetricScreen** - Pantalla genérica que muestra la interfaz y funcionalidad de cualquier métrica
3. **Configuraciones específicas** - Clases como `BoltMetricConfig` que contienen la configuración para métricas específicas
4. **MetricRegistry** - Registro central de todas las métricas disponibles
5. **Widgets relacionados** - Componentes de UI como `MetricInstructionCard`, `MetricInstructionOverlay`, etc.

## Cómo Agregar una Nueva Métrica

### 1. Crear una Configuración para la Métrica

Crear un nuevo archivo en `lib/config/` siguiendo el patrón de `bolt_metric_config.dart`:

```dart
// lib/config/my_metric_config.dart
import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import '../constants/images.dart';

/// Configuración específica para Mi Métrica
class MyMetricConfig {
  /// Obtener la configuración de Mi Métrica
  static MetricConfig get config => MetricConfig(
        tableName: 'my_metric_scores',        // Nombre de la tabla en la base de datos
        scoreFieldName: 'score_value',        // Campo de la puntuación en la tabla
        metricName: 'MI MÉTRICA',             // Nombre de la métrica
        screenTitle: 'Mide tu capacidad X',   // Título en la pantalla
        metricDescription: 'Descripción corta de lo que mide la métrica...',
        longDescription: 'Descripción larga y detallada sobre la métrica...',
        measurementInstructions: 'Instrucciones adicionales (opcional)',
        startButtonText: 'COMENZAR',
        stopButtonText: 'DETENER',
        instructionImage: Images.someImage,   // Imagen para la métrica
        simplifiedInstructions: [
          '1. Primer paso simple',
          '2. Segundo paso simple',
          '3. Tercer paso simple',
        ],
        instructionSteps: [
          // Pasos detallados con tiempos/animaciones
          MetricInstructionStep(
            instructionText: 'Paso 1: haz esto',
            allowManualAdvance: true,
          ),
          MetricInstructionStep(
            instructionText: 'Paso 2: inhala',
            duration: const Duration(seconds: 5),
            requiresBreathVisualization: true, 
            isInhale: true,
          ),
          // ... más pasos según sea necesario
        ],
        scoreZones: [
          // Define las zonas de puntuación y sus significados
          ScoreZone(
            maxValue: 10.0,
            label: '<10 - Bajo',
            description: 'Explicación para puntuaciones bajas',
            color: Colors.redAccent.shade200,
          ),
          // ... más zonas según sea necesario
        ],
        formatScore: (score) => '$score unidades',
        buildDetailedInstructions: (context) {
          // Construir las instrucciones detalladas para el diálogo
          return [
            _buildInstructionStep(context, 1, 'Instrucción detallada 1'),
            // ... más instrucciones detalladas
          ];
        },
      );

  /// Método auxiliar para construir los pasos de instrucción detallados
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
```

### 2. Registrar la Métrica en el Registro

Agregar la nueva métrica al registro en `lib/config/metric_registry.dart`:

```dart
static List<MetricConfig> get availableMetrics => [
  BoltMetricConfig.config,
  MyMetricConfig.config,   // Agregar la nueva métrica aquí
  // Agregar más métricas según sea necesario
];
```

También actualizar la función `getIconForMetric` para asignar un ícono adecuado:

```dart
static IconData getIconForMetric(String metricName) {
  switch (metricName.toUpperCase()) {
    case 'BOLT':
      return Icons.psychology;
    case 'MI MÉTRICA':  // Agregar el nuevo caso
      return Icons.favorite;
    default:
      return Icons.show_chart;
  }
}
```

### 3. Crear una Pantalla Wrapper

Crear un archivo para la pantalla en `lib/screens/`:

```dart
// lib/screens/my_metric_screen.dart
import 'package:flutter/material.dart';
import '../config/my_metric_config.dart';
import 'metric_screen.dart';

/// Pantalla para la métrica MI MÉTRICA
class MyMetricScreen extends StatefulWidget {
  const MyMetricScreen({super.key});

  @override
  State<MyMetricScreen> createState() => _MyMetricScreenState();
}

class _MyMetricScreenState extends State<MyMetricScreen> {
  @override
  Widget build(BuildContext context) {
    // Usar la pantalla genérica con la configuración específica
    return MetricScreen(
      metricConfig: MyMetricConfig.config,
      initialAggregation: Aggregation.week,
    );
  }
}
```

### 4. Agregar la Ruta (Opcional)

Si la métrica debe ser accesible directamente desde una URL, agregar la ruta en `lib/main.dart`:

```dart
// Dentro de la lista de rutas en GoRouter
GoRoute(
  path: '/mimetrica',  // Ruta en minúsculas
  builder: (context, state) => const MyMetricScreen(),
),
```

### 5. Crear la Tabla de Base de Datos

Finalmente, crear la tabla adecuada en Supabase para almacenar las puntuaciones:

```sql
-- Tabla para almacenar puntuaciones de la nueva métrica
CREATE TABLE my_metric_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  score_value INTEGER NOT NULL,  -- O el tipo de dato apropiado
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Configurar RLS (Row Level Security)
ALTER TABLE my_metric_scores ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios pueden ver sus propias puntuaciones"
  ON my_metric_scores FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden insertar sus propias puntuaciones"
  ON my_metric_scores FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## Notas Importantes

1. **Imágenes**: Asegúrate de agregar cualquier imagen necesaria a `assets/images/` y referenciarla en `lib/constants/images.dart`.

2. **Zonas de Puntuación**: Las zonas de puntuación deben estar en orden ascendente según su valor máximo, y la última zona debe tener `maxValue: double.infinity`.

3. **Personalización**: Todos los aspectos de la métrica son personalizables, incluyendo textos, colores, pasos, instrucciones, etc.

4. **Base de Datos**: Asegúrate de crear la tabla de base de datos correctamente con las políticas RLS adecuadas.

5. **Pruebas**: Siempre prueba la nueva métrica en diferentes tamaños de pantalla para verificar que la interfaz se vea correctamente.

Con estos pasos, puedes crear nuevas métricas de respiración/estrés en la aplicación de manera fácil y consistente. 