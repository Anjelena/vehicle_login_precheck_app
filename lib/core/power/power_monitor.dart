import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';

/// Watches the device charging state and exposes a [hasPower] flag.
///
/// `hasPower = true` means the tablet is plugged in (vehicle ignition on,
/// charger connected, etc.). `hasPower = false` means it's on battery, which
/// for our deployment means the ignition has been turned off.
///
/// Wraps the `battery_plus` plugin. Reading battery state needs no Android
/// permissions.
class PowerMonitor extends ChangeNotifier {
  PowerMonitor({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;
  StreamSubscription<BatteryState>? _sub;
  BatteryState _state = BatteryState.unknown;

  BatteryState get state => _state;

  /// True when the device is plugged into external power.
  ///
  /// `unknown` is treated optimistically (true) so cold start with no signal
  /// yet doesn't immediately trip the power-loss overlay.
  bool get hasPower {
    switch (_state) {
      case BatteryState.full:
      case BatteryState.charging:
      case BatteryState.connectedNotCharging:
        return true;
      case BatteryState.discharging:
        return false;
      case BatteryState.unknown:
        return true;
    }
  }

  /// Read the initial state and start listening for changes.
  Future<void> start() async {
    try {
      _state = await _battery.batteryState;
      AppLogger.i('PowerMonitor: initial state=$_state (hasPower=$hasPower)');
      notifyListeners();
    } catch (e) {
      AppLogger.w('PowerMonitor: failed to read initial state: $e');
    }

    _sub = _battery.onBatteryStateChanged.listen((s) {
      if (s == _state) return;
      _state = s;
      AppLogger.i('PowerMonitor: state=$s (hasPower=$hasPower)');
      notifyListeners();
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
