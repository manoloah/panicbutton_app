import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/widgets/breath_circle.dart';

class BreathingLoadingAnimation extends ConsumerStatefulWidget {
  final String loadingText;
  final bool showQuote;

  const BreathingLoadingAnimation({
    Key? key,
    this.loadingText = 'Cargando ejercicios...',
    this.showQuote = true,
  }) : super(key: key);

  @override
  ConsumerState<BreathingLoadingAnimation> createState() =>
      _BreathingLoadingAnimationState();
}

class _BreathingLoadingAnimationState
    extends ConsumerState<BreathingLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String _quote = '';

  // List of quotes in Spanish about breathing and calmness
  static const List<String> _quotes = [
    "La respiración es el puente que conecta la vida con la conciencia, que une tu cuerpo con tus pensamientos. — Thích Nhất Hạnh",
    "La paz comienza con una sonrisa. — Madre Teresa de Calcuta",
    "No puedes calmar la tormenta, así que deja de intentarlo. Lo que puedes hacer es calmarte a ti mismo. La tormenta pasará. — Timber Hawkeye",
    "La calma es la clave del dominio propio. — Lao Tse",
    "La respiración consciente es mi ancla en el presente. — Thich Nhat Hanh",
    "Respirar es el primer acto de la vida y el último. Respira bien y vivirás bien. — Joseph Pilates",
    "Si controlas tu respiración, controlarás tu mente. — B.K.S. Iyengar",
    "La paz interior comienza en el momento en que decides no permitir que otra persona o evento controle tus emociones. — Pema Chödrön",
    "Cuando el aliento fluye fácilmente, la mente está tranquila. — Patanjali",
    "La respiración es el puente entre tu cuerpo y tu mente. Aprende a dominarla y dominarás tu vida. — Wim Hof",
    "Cuando te sientes ansioso, respira. Cuando te sientes abrumado, respira. La respuesta está en tu respiración. — Wim Hof",
    "La calma es un componente clave de la grandeza. Los campeones mantienen la calma bajo presión. — Michael Jordan",
    "La respiración es la herramienta más poderosa que tienes. Te conecta con el presente y te prepara para la grandeza. — George Mumford",
    "Cuanto más tranquilo estás, más rápido puedes reaccionar. — Usain Bolt",
    "El control de la respiración es el control de la mente. Los mejores atletas lo saben y lo practican. — Wim Hof",
    "El verdadero desafío no está en la competencia, sino en mantener la calma en medio del caos. — Kobe Bryant",
    "Respira profundo. Ese es tu centro. Ese es tu poder. — Phil Jackson",
    "La respiración es la clave para liberar la tensión en el cuerpo y la mente. Es tu aliado en la batalla por la victoria. — Laird Hamilton",
    "La respiración consciente es una de las formas más importantes de superar momentos difíciles. Me ayuda a mantenerme presente y enfocado. — Novak Djokovic",
    "Antes de cada tiro libre, respiro profundamente. Es mi forma de resetear el sistema nervioso y mantener la concentración. — Cristiano Ronaldo",
  ];

  @override
  void initState() {
    super.initState();

    // Select a random quote
    final random = math.Random();
    _quote = _quotes[random.nextInt(_quotes.length)];

    // Create animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Create animations
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation and make it repeat
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isConstrained = constraints.maxHeight < 250;
      final useCompactLayout = isConstrained;
      final circleSize = useCompactLayout ? 80.0 : 180.0;

      return Center(
        child: SingleChildScrollView(
          physics:
              useCompactLayout ? const NeverScrollableScrollPhysics() : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Removed PanicButton title
                SizedBox(height: useCompactLayout ? 10 : 20),

                // Animated breathing circle
                SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Use the existing BreathCircle with isBreathing set to true
                              BreathCircle(
                                onTap: () {},
                                isBreathing: true,
                                size: circleSize,
                                phaseIndicator: const CircleWaveOverlay(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: useCompactLayout ? 10 : 30),
                Text(
                  widget.loadingText,
                  style: useCompactLayout
                      ? textTheme.bodyMedium
                      : textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                // Show quote if enabled and there's enough space
                if (widget.showQuote && !useCompactLayout) ...[
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: _formatQuote(_quote),
                        style: textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface
                              .withAlpha((0.7 * 255).toInt()),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  List<TextSpan> _formatQuote(String quote) {
    // Split by the delimiter '—' to separate quote from author
    final parts = quote.split('—');

    if (parts.length < 2) {
      return [TextSpan(text: '"$quote"')];
    }

    // Get the quote text and author
    final quoteText = parts[0].trim();
    final authorText = parts[1].trim();

    // Return the formatted text spans with different styling for the author
    return [
      TextSpan(text: '"$quoteText" '),
      TextSpan(
        text: '—$authorText',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          fontStyle: FontStyle.normal,
        ),
      ),
    ];
  }
}
