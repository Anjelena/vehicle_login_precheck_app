import 'package:sqflite/sqflite.dart';
import 'package:rfid_scanner_app/features/auth/data/auth_repository.dart';
import 'package:rfid_scanner_app/features/auth/domain/authenticated_user.dart';

/// Dummy SQLite-backed [AuthRepository] used during development.
///
/// Reads from the `cards` table created by `AppDatabase`. Will be replaced by
/// the integrating team's implementation in production.
class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository(this._db);

  final Database _db;

  @override
  Future<AuthenticatedUser?> lookupCard(int cardNo) async {
    final rows = await _db.query(
      'cards',
      where: 'card_no = ?',
      whereArgs: [cardNo],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final r = rows.first;
    return AuthenticatedUser(
      cardNo: r['card_no'] as int,
      name: r['name'] as String,
    );
  }
}
