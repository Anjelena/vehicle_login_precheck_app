import 'package:flutter/material.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppTheme.accent
              : AppTheme.secondaryText.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
