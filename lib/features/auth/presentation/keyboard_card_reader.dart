import 'dart:async';
import 'package:flutter/services.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';

/// Buffers keystrokes from a HID-style RFID reader (e.g. Flipper Zero in
/// keyboard-emulator mode) into card numbers.
///
/// Accepts decimal digits and hex letters. Fires [onCardScanned] when:
///  - the user (or reader) presses Enter, OR
///  - 500 ms passes with no new keystroke.
///
/// Tries to parse the buffered string as decimal first, then as hex. If neither
/// works (or the buffer is shorter than [_minCardLength]), the input is logged
/// and discarded — protects against accidental keystrokes on a dev tablet.
class KeyboardCardReader {
  KeyboardCardReader({this.onCardScanned});

  void Function(int cardNo)? onCardScanned;

  static const Duration _idleTimeout = Duration(milliseconds: 500);
  static const int _minCardLength = 4;

  final StringBuffer _input = StringBuffer();
  Timer? _timeout;

  void handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _flush();
      return;
    }

    final char = event.character;
    if (char != null && _isCardChar(char)) {
      _input.write(char.toUpperCase());
      _timeout?.cancel();
      _timeout = Timer(_idleTimeout, _flush);
    }
  }

  void _flush() {
    _timeout?.cancel();
    _timeout = null;

    final raw = _input.toString();
    _input.clear();

    if (raw.length < _minCardLength) {
      if (raw.isNotEmpty) {
        AppLogger.d('KeyboardCardReader: ignoring short input "$raw"');
      }
      return;
    }

    final cardNo = int.tryParse(raw) ?? int.tryParse(raw, radix: 16);
    if (cardNo != null) {
      AppLogger.i('KeyboardCardReader: parsed cardNo=$cardNo from "$raw"');
      onCardScanned?.call(cardNo);
    } else {
      AppLogger.w('KeyboardCardReader: unparseable input "$raw"');
    }
  }

  static bool _isCardChar(String char) {
    if (char.length != 1) return false;
    return RegExp(r'^[0-9A-Fa-f]$').hasMatch(char);
  }

  void dispose() {
    _timeout?.cancel();
  }
}
