/// Represents a successfully authenticated user.
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.cardNo,
    required this.name,
  });

  /// Decimal card number, the lookup key. Comes from the PCB JSON
  /// (`{"CardNo": <int>}`) or from a parsed keyboard-emulator scan.
  final int cardNo;

  /// Display name, e.g. for the welcome screen.
  final String name;
}
