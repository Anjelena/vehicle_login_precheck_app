import 'package:rfid_scanner_app/features/auth/domain/authenticated_user.dart';

/// Authentication data source.
///
/// **This is the integration boundary.** The production app should provide an
/// implementation of this interface (e.g. backed by their existing data layer)
/// and inject it at the top of the widget tree, replacing the dummy
/// `SqliteAuthRepository` used during development.
///
/// The contract is intentionally narrow: a single card-lookup operation.
abstract class AuthRepository {
  /// Look up a card by its decimal card number.
  ///
  /// Returns the matching [AuthenticatedUser] if the card is registered, or
  /// `null` if no card with that number exists (treat as access denied).
  ///
  /// May throw if the underlying data source is unavailable; callers should
  /// surface this as a system error.
  Future<AuthenticatedUser?> lookupCard(int cardNo);
}
