import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:rfid_scanner_app/core/config.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';
import 'package:usb_serial/usb_serial.dart';

/// Auto-connects to the RFID PCB over USB-CDC and parses scanned cards.
///
/// Protocol (confirmed via the PCB inspector tool):
///   * USB-CDC serial, 115200 8N1 (baud rate is metadata only — native CDC).
///   * One JSON object per line, terminated by `\r\n`.
///   * Payload: `{"CardNo": <int>}` — additional fields are ignored.
///
/// Auto-connects to the first device matching [AppConfig.pcbUsbVid]. Reconnects
/// automatically on USB attach; clears state on detach. The class makes no UI
/// — connection is invisible to the user.
class SerialCardReader {
  SerialCardReader({this.onCardScanned});

  void Function(int cardNo)? onCardScanned;

  StreamSubscription<UsbEvent>? _eventSub;
  StreamSubscription<Uint8List>? _serialSub;
  UsbPort? _port;
  bool _running = false;
  final StringBuffer _lineBuffer = StringBuffer();

  /// Begin watching for the PCB and connect when present.
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _eventSub = UsbSerial.usbEventStream?.listen((event) async {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        await _tryConnect();
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        await _disconnectInternal();
      }
    });
    await _tryConnect();
  }

  /// Stop and release any held resources.
  Future<void> stop() async {
    _running = false;
    await _eventSub?.cancel();
    _eventSub = null;
    await _disconnectInternal();
  }

  Future<void> _tryConnect() async {
    if (!_running || _port != null) return;

    final devices = await UsbSerial.listDevices();
    UsbDevice? match;
    for (final d in devices) {
      if (d.vid == AppConfig.pcbUsbVid) {
        match = d;
        break;
      }
    }
    if (match == null) return;

    try {
      final port = await match.create();
      if (port == null) {
        AppLogger.w('SerialCardReader: create() returned null '
            '(driver not supported for VID=${_hex16(match.vid)})');
        return;
      }
      if (!await port.open()) {
        AppLogger.w('SerialCardReader: open() failed (permission denied?)');
        return;
      }
      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        AppConfig.pcbBaudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      _port = port;
      _serialSub = port.inputStream?.listen(
        _onBytes,
        onDone: _disconnectInternal,
        onError: (Object e) =>
            AppLogger.w('SerialCardReader: stream error: $e'),
      );
      AppLogger.i('SerialCardReader: connected to '
          '"${match.productName ?? "PCB"}" '
          '(${_hex16(match.vid)}:${_hex16(match.pid)})');
    } catch (e) {
      AppLogger.e('SerialCardReader: connect error: $e');
    }
  }

  Future<void> _disconnectInternal() async {
    await _serialSub?.cancel();
    _serialSub = null;
    try {
      await _port?.close();
    } catch (_) {}
    _port = null;
    _lineBuffer.clear();
    if (_running) {
      AppLogger.w('SerialCardReader: disconnected');
    }
  }

  void _onBytes(Uint8List bytes) {
    _lineBuffer.write(String.fromCharCodes(bytes));
    final str = _lineBuffer.toString();
    final parts = str.split('\n');
    for (var i = 0; i < parts.length - 1; i++) {
      _handleLine(parts[i].trim());
    }
    _lineBuffer
      ..clear()
      ..write(parts.last);
  }

  void _handleLine(String line) {
    if (line.isEmpty) return;

    try {
      final decoded = jsonDecode(line);
      if (decoded is Map) {
        final raw = decoded['CardNo'];
        final cardNo = (raw is int)
            ? raw
            : (raw is String ? int.tryParse(raw) : null);
        if (cardNo != null) {
          AppLogger.i('SerialCardReader: scanned cardNo=$cardNo');
          onCardScanned?.call(cardNo);
          return;
        }
      }
    } catch (_) {
      // Not JSON or wrong shape — fall through to warn.
    }

    AppLogger.w('SerialCardReader: skipping unparseable line: $line');
  }

  static String _hex16(int? v) =>
      v == null ? '????' : '0x${v.toRadixString(16).padLeft(4, '0').toUpperCase()}';
}
