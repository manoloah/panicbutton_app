import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';

class DurationSelectorButton extends ConsumerWidget {
  const DurationSelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDuration = ref.watch(selectedDurationProvider);

    return GestureDetector(
      onTap: () => _showDurationPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Duración: $selectedDuration min',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref) {
    final currentDuration = ref.read(selectedDurationProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DurationPickerSheet(initialValue: currentDuration),
    );
  }
}

class _DurationPickerSheet extends ConsumerStatefulWidget {
  final int initialValue;

  const _DurationPickerSheet({required this.initialValue});

  @override
  ConsumerState<_DurationPickerSheet> createState() =>
      _DurationPickerSheetState();
}

class _DurationPickerSheetState extends ConsumerState<_DurationPickerSheet> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Selecciona la duración',
              style: tt.titleLarge,
            ),
            const SizedBox(height: 8),

            Text(
              '$_selectedDuration minutos',
              style: tt.displaySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            CupertinoSlider(
              value: _selectedDuration.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: cs.primary,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value.round();
                });
              },
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Duration presets
                _buildDurationChip(1),
                _buildDurationChip(3),
                _buildDurationChip(5),
                _buildDurationChip(10),
                _buildDurationChip(15),
                _buildDurationChip(30),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                ref.read(selectedDurationProvider.notifier).state =
                    _selectedDuration;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Aplicar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedDuration == minutes;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = minutes;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$minutes',
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
