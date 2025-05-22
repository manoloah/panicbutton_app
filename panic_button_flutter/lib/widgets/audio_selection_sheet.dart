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
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                children: [
                  // Sheet handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(77), // 30% opacity
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Audio',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tones Section
                    _buildSectionTitle(context, 'Tonos'),
                    const SizedBox(height: 8),
                    _AudioSelectionGrid(
                      audioType: AudioType.breathGuide,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 24),

                    // Background Music Section
                    _buildSectionTitle(context, 'Música de fondo'),
                    const SizedBox(height: 8),
                    _AudioSelectionGrid(
                      audioType: AudioType.backgroundMusic,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 24),

                    // Guiding Voice Section
                    _buildSectionTitle(context, 'Voces'),
                    const SizedBox(height: 8),
                    _AudioSelectionGrid(
                      audioType: AudioType.guidingVoice,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom button area with save
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
        textAlign: TextAlign.left,
      ),
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
    final cs = Theme.of(context).colorScheme;

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

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    final buttonSize = isSmallScreen ? 50.0 : 60.0;

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
              color: cs.surfaceVariant.withOpacity(0.8),
              border: Border.all(
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                track.icon,
                size: isSmallScreen ? 20 : 24,
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          track.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
