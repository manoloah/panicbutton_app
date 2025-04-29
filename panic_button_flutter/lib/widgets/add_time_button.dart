import 'package:flutter/material.dart';

class AddTimeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddTimeButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('+3 minutos'),
    );
  }
}
