import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rfid_scanner_app/core/db/seed_data.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';

/// Opens (and seeds, on first run) the local dummy SQLite database.
///
/// Development-only data source. Production integration replaces the
/// SQLite-backed repositories with its own implementations of the abstract
/// `AuthRepository` and `PrestartRepository`.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _dbName = 'rfid_scanner.db';

  /// Schema version history:
  ///   * v1 — chunk 1: original `cards (card_id TEXT PRIMARY KEY, ...)`.
  ///   * v2 — chunk 1.5: `cards` reshaped around `card_no INTEGER`.
  ///   * v3 — chunk 1.5: dual seed (PCB + Flipper card numbers).
  ///   * v4 — chunk 2: prestart tables added; questions seeded from asset.
  ///
  /// On every bump we drop and recreate (dev simplicity).
  static const _dbVersion = 4;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    AppLogger.i('Opening SQLite at $path');

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
    await _seedCards(db);
    await _seedPrestart(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.i('Upgrading SQLite v$oldVersion → v$newVersion (drop & recreate)');
    await db.execute('DROP TABLE IF EXISTS cards');
    await db.execute('DROP TABLE IF EXISTS prestart_questions');
    await db.execute('DROP TABLE IF EXISTS prestart_meta');
    await db.execute('DROP TABLE IF EXISTS prestart_submissions');
    await _createSchema(db);
    await _seedCards(db);
    await _seedPrestart(db);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE cards (
        card_no  INTEGER PRIMARY KEY,
        name     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE prestart_meta (
        key    TEXT PRIMARY KEY,
        value  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE prestart_questions (
        id              INTEGER PRIMARY KEY,
        category        TEXT NOT NULL,
        question        TEXT NOT NULL,
        correct_answer  TEXT NOT NULL,
        is_required     INTEGER NOT NULL,
        is_key_safety   INTEGER NOT NULL,
        display_order   INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE prestart_submissions (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        card_no          INTEGER NOT NULL,
        user_name        TEXT NOT NULL,
        submitted_at     TEXT NOT NULL,
        check_title      TEXT NOT NULL,
        total_questions  INTEGER NOT NULL,
        answered_count   INTEGER NOT NULL,
        all_correct      INTEGER NOT NULL,
        answers_json     TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _seedCards(Database db) async {
    final batch = db.batch();
    for (final card in seedCards) {
      batch.insert('cards', card);
    }
    await batch.commit(noResult: true);
    AppLogger.i('Seeded ${seedCards.length} card(s)');
  }

  static Future<void> _seedPrestart(Database db) async {
    final jsonStr = await rootBundle.loadString('assets/prestart_questions.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final title = data['title'] as String? ?? 'Prestart Check';
    await db.insert('prestart_meta', {'key': 'check_title', 'value': title});

    final questions = (data['questions'] as List).cast<Map<String, dynamic>>();
    final batch = db.batch();
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      batch.insert('prestart_questions', {
        'id': q['id'],
        'category': q['category'],
        'question': q['question'],
        'correct_answer': q['correctAnswer'],
        'is_required': (q['required'] ?? true) == true ? 1 : 0,
        'is_key_safety': (q['keySafetyFeature'] ?? false) == true ? 1 : 0,
        'display_order': i,
      });
    }
    await batch.commit(noResult: true);
    AppLogger.i('Seeded ${questions.length} prestart question(s) ("$title")');
  }
}
