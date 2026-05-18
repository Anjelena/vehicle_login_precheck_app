import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/power/power_sleep_coordinator.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';

/// Fullscreen translucent overlay shown while the power-lost shutdown timer
/// is running. Absorbs touches so the user can't interact with the underlying
/// screen during the countdown.
class PowerShutdownOverlay extends StatelessWidget {
  const PowerShutdownOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PowerSleepCoordinator>(
      builder: (context, coordinator, _) {
        if (!coordinator.isCountingDown) return const SizedBox.shrink();
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              color: Colors.black.withValues(alpha: 0.88),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.power_off,
                      color: AppTheme.warning,
                      size: 96,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Power Lost',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.warning,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Logging out in ${coordinator.remainingSeconds} seconds',
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Reconnect to power to cancel.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
