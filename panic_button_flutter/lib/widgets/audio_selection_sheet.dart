import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/services/audio_service.dart';

/// Bottom sheet for selecting audio options during breathing exercises
class AudioSelectionSheet extends ConsumerWidget {
  const AudioSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet handle and title - fixed part
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: [
                  // Sheet handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(77), // 30% opacity
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Audio',
                        style: tt.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Background Music Section
                    _buildSectionTitle(context, 'Tono de Inhalar / Exhalar'),
                    const SizedBox(height: 16),
                    _AudioSelectionGrid(
                      audioType: AudioType.breathGuide,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 32),

                    // Soundscape Section
                    _buildSectionTitle(context, 'Paisaje Sonoro'),
                    const SizedBox(height: 16),
                    _AudioSelectionGrid(
                      audioType: AudioType.backgroundMusic,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 32),

                    // Voice Guide Section
                    _buildSectionTitle(context, 'Guía de Voz'),
                    const SizedBox(height: 16),
                    _AudioSelectionGrid(
                      audioType: AudioType.ambientSound,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }
}

/// Grid of audio selection options
class _AudioSelectionGrid extends ConsumerWidget {
  final AudioType audioType;
  final bool isSmallScreen;

  const _AudioSelectionGrid({
    required this.audioType,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final selectedTrackId = ref.watch(selectedAudioProvider(audioType));
    final tracks = audioService.getTracksByType(audioType);

    // Check if we have enough tracks to show a grid
    if (tracks.length <= 1) {
      // Just show the "Off" option
      return Center(
        child: _AudioOptionButton(
          track: tracks.first,
          isSelected: true,
          onTap: () {},
          isSmallScreen: isSmallScreen,
        ),
      );
    }

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface
              .withAlpha(77), // 30% opacity
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: tracks.map((track) {
            final isSelected = selectedTrackId == track.id;
            return _AudioOptionButton(
              track: track,
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(selectedAudioProvider(audioType).notifier)
                    .selectTrack(track.id);
              },
              isSmallScreen: isSmallScreen,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Individual audio option button
class _AudioOptionButton extends StatelessWidget {
  final AudioTrack track;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _AudioOptionButton({
    required this.track,
    required this.isSelected,
    required this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buttonSize = isSmallScreen ? 64.0 : 80.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border:
                  isSelected ? Border.all(color: cs.primary, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                track.icon,
                size: isSmallScreen ? 24 : 32,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          track.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? cs.primary : cs.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
