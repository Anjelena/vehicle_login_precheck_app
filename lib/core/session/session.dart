import 'package:flutter/foundation.dart';
import 'package:rfid_scanner_app/features/auth/domain/authenticated_user.dart';

/// Holds the currently logged-in user. App-wide singleton-style state, but
/// exposed via Provider so consumers can listen for changes.
class Session extends ChangeNotifier {
  AuthenticatedUser? _user;
  DateTime? _loginTime;

  AuthenticatedUser? get user => _user;
  DateTime? get loginTime => _loginTime;
  bool get isLoggedIn => _user != null;

  void login(AuthenticatedUser user) {
    _user = user;
    _loginTime = DateTime.now();
    notifyListeners();
  }

  void logout() {
    _user = null;
    _loginTime = null;
    notifyListeners();
  }
}
