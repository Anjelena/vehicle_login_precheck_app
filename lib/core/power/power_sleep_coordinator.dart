import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';
import 'package:rfid_scanner_app/core/power/power_monitor.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/session/session.dart';

/// Coordinates the "vehicle ignition off → 10 s grace → logout & sleep" flow.
///
/// Listens to [PowerMonitor]. When power is lost while the app is in any
/// user-facing state, starts a [shutdownDuration] countdown. If power is
/// restored before the timer expires, the countdown is cancelled. On expiry
/// the user is logged out and the app navigates to the no-power screen.
///
/// The coordinator exposes [isCountingDown] and [remainingSeconds] so a
/// fullscreen overlay can show the countdown to the operator.
class PowerSleepCoordinator extends ChangeNotifier {
  PowerSleepCoordinator({
    required this.powerMonitor,
    required this.session,
    required this.navigatorKey,
    this.shutdownDuration = const Duration(seconds: 10),
  }) {
    powerMonitor.addListener(_onPowerChange);
  }

  final PowerMonitor powerMonitor;
  final Session session;
  final GlobalKey<NavigatorState> navigatorKey;
  final Duration shutdownDuration;

  Timer? _ticker;
  int _remainingSeconds = 0;
  bool _isCountingDown = false;

  bool get isCountingDown => _isCountingDown;
  int get remainingSeconds => _remainingSeconds;

  void _onPowerChange() {
    if (powerMonitor.hasPower) {
      if (_isCountingDown) {
        AppLogger.i('PowerSleepCoordinator: power restored, cancelling shutdown');
      }
      _cancelCountdown();
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (_isCountingDown) return;
    _isCountingDown = true;
    _remainingSeconds = shutdownDuration.inSeconds;
    AppLogger.i('PowerSleepCoordinator: power lost, '
        'starting ${shutdownDuration.inSeconds}s shutdown countdown');
    notifyListeners();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        _executeShutdown();
      } else {
        notifyListeners();
      }
    });
  }

  void _cancelCountdown() {
    if (!_isCountingDown) return;
    _ticker?.cancel();
    _ticker = null;
    _isCountingDown = false;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void _executeShutdown() {
    _ticker?.cancel();
    _ticker = null;
    _isCountingDown = false;
    _remainingSeconds = 0;
    AppLogger.i('PowerSleepCoordinator: countdown expired, logging out');
    session.logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.noPower,
      (_) => false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    powerMonitor.removeListener(_onPowerChange);
    _ticker?.cancel();
    super.dispose();
  }
}
