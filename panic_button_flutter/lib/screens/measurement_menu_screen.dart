import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/custom_sliver_app_bar.dart';

/// Screen that displays a menu of available measurement tests
class MeasurementMenuScreen extends StatelessWidget {
  const MeasurementMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            CustomSliverAppBar(
              showBackButton: true,
              backRoute: '/breath',
              title: Text(
                '',
                style: tt.headlineMedium,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title & description - more compact
                  Text(
                    'Selecciona la prueba que quieres realizar:',
                    style: tt.headlineSmall, // Smaller title
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20), // Reduced spacing

                  // BOLT Test Card
                  _buildTestCard(
                    context: context,
                    title: 'BOLT',
                    subtitle: 'Límite inferior',
                    description:
                        'Mide tu capacidad en reposo para calmarte, dormir, recuperarte, y manejar el estrés a corto plazo.',
                    onTap: () => context.go('/bolt'),
                    isSelected: false,
                  ),

                  const SizedBox(height: 16), // Reduced spacing between cards

                  // MBT Test Card
                  _buildTestCard(
                    context: context,
                    title: 'MBT',
                    subtitle: 'Umbral de resistencia',
                    description:
                        'Evalúa tu capacidad de sostener estrés físico y mental de forma prolongada.',
                    onTap: () => context.go('/mbt'),
                    isSelected: false, // Remove highlight
                  ),

                  // Dynamic bottom padding for navbar
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }

  Widget _buildTestCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18), // Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(16), // Smaller radius
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outline.withAlpha((0.3 * 255).toInt()),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 6, // Reduced shadow
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and subtitle - more compact
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.headlineMedium?.copyWith(
                    // Smaller title
                    fontWeight: FontWeight.bold,
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  subtitle,
                  style: tt.titleSmall?.copyWith(
                    // Smaller subtitle
                    color: isSelected
                        ? cs.onPrimaryContainer.withAlpha((0.8 * 255).toInt())
                        : cs.onSurface.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing

            // Description - more compact
            Text(
              description,
              style: tt.bodyMedium?.copyWith(
                // Smaller description
                color: isSelected
                    ? cs.onPrimaryContainer.withAlpha((0.9 * 255).toInt())
                    : cs.onSurface.withAlpha((0.8 * 255).toInt()),
                height: 1.3, // Tighter line height
              ),
              maxLines: 3, // Limit lines to save space
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14), // Reduced spacing

            // Action button - using secondary button style, more compact
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 12), // Reduced padding
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Smaller radius
                        ),
                      ),
                    ),
                child: Text(
                  'COMENZAR PRUEBA',
                  style: tt.titleSmall?.copyWith(
                    // Smaller button text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
