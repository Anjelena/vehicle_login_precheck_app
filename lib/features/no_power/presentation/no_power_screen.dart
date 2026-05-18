import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/power/power_monitor.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';

/// Terminal "ignition off" screen. Shown when the tablet has no external
/// power — either after a power-loss countdown expires (via
/// `PowerSleepCoordinator`) or on cold boot with the ignition off (selected
/// by `App` as `initialRoute`).
///
/// Listens to [PowerMonitor] and auto-navigates to the login screen when
/// power is restored.
class NoPowerScreen extends StatefulWidget {
  const NoPowerScreen({super.key});

  @override
  State<NoPowerScreen> createState() => _NoPowerScreenState();
}

class _NoPowerScreenState extends State<NoPowerScreen> {
  late final PowerMonitor _monitor;

  @override
  void initState() {
    super.initState();
    _monitor = context.read<PowerMonitor>();
    _monitor.addListener(_onPowerChange);
  }

  @override
  void dispose() {
    _monitor.removeListener(_onPowerChange);
    super.dispose();
  }

  void _onPowerChange() {
    if (_monitor.hasPower && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_off,
              color: AppTheme.secondaryText.withValues(alpha: 0.6),
              size: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'Ignition Off',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.secondaryText,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Restore power to continue.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
