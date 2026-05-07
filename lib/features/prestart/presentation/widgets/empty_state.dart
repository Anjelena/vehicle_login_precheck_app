import 'package:flutter/material.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.secondaryText, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }
}
