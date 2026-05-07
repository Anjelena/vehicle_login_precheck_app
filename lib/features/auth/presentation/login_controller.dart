import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/features/auth/data/auth_repository.dart';

enum LoginStatus { idle, validating, success, failure }

/// Drives the login screen. Looks up scanned cards via [AuthRepository] and
/// updates [Session] on success.
class LoginController extends ChangeNotifier {
  LoginController({
    required AuthRepository authRepository,
    required Session session,
  })  : _authRepository = authRepository,
        _session = session;

  final AuthRepository _authRepository;
  final Session _session;

  LoginStatus _status = LoginStatus.idle;
  int? _lastCardNo;
  String? _errorMessage;
  Timer? _failureResetTimer;

  LoginStatus get status => _status;
  int? get lastCardNo => _lastCardNo;
  String? get errorMessage => _errorMessage;

  /// Submit a scanned card for validation. Idempotent against quick double-fires
  /// from both serial + keyboard readers — submissions while not idle are
  /// dropped.
  Future<void> submitCard(int cardNo) async {
    if (_status != LoginStatus.idle) return;

    _failureResetTimer?.cancel();
    _lastCardNo = cardNo;
    _status = LoginStatus.validating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.lookupCard(cardNo);
      if (user != null) {
        _session.login(user);
        _setResult(LoginStatus.success, null);
        AppLogger.i('Login SUCCESS for cardNo=$cardNo (${user.name})');
      } else {
        _setResult(LoginStatus.failure, 'Access denied.');
        AppLogger.w('Login FAILURE: cardNo=$cardNo not found');
      }
    } catch (e) {
      AppLogger.e('Login error for cardNo=$cardNo: $e');
      _setResult(LoginStatus.failure, 'System error.');
    }
  }

  void _setResult(LoginStatus result, String? errorMsg) {
    _status = result;
    _errorMessage = errorMsg;
    notifyListeners();

    // Only auto-reset on failure. Success is terminal — the screen navigates
    // forward once the user has had a moment to see "Card Authorised".
    if (result == LoginStatus.failure) {
      _failureResetTimer = Timer(const Duration(seconds: 3), () {
        _status = LoginStatus.idle;
        _lastCardNo = null;
        _errorMessage = null;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _failureResetTimer?.cancel();
    super.dispose();
  }
}
