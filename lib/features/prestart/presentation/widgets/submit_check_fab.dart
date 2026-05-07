import 'package:flutter/material.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';

class SubmitCheckFAB extends StatelessWidget {
  const SubmitCheckFAB({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.accent,
      icon: const Icon(Icons.check, color: AppTheme.primaryText),
      label: const Text(
        'Submit Check',
        style: TextStyle(
          color: AppTheme.primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
