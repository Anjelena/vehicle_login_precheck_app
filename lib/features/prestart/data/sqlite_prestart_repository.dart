import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:rfid_scanner_app/features/prestart/data/prestart_repository.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_check.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_question.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_submission.dart';

/// Dummy SQLite-backed [PrestartRepository] used during development.
///
/// Reads questions from the `prestart_questions` table (seeded from the
/// `assets/prestart_questions.json` asset on first install). Submissions are
/// inserted into `prestart_submissions` as an audit log; the per-question
/// answers are stored as a JSON blob in the same row to keep the schema
/// simple.
class SqlitePrestartRepository implements PrestartRepository {
  SqlitePrestartRepository(this._db);

  final Database _db;

  @override
  Future<PrestartCheck> loadCheck() async {
    final metaRows = await _db.query(
      'prestart_meta',
      where: 'key = ?',
      whereArgs: ['check_title'],
      limit: 1,
    );
    final title = metaRows.isNotEmpty
        ? metaRows.first['value'] as String
        : 'Prestart Check';

    final qRows = await _db.query(
      'prestart_questions',
      orderBy: 'display_order ASC',
    );
    final questions = qRows
        .map((r) => PrestartQuestion(
              id: r['id'] as int,
              category: r['category'] as String,
              question: r['question'] as String,
              correctAnswer: r['correct_answer'] as String,
              required: (r['is_required'] as int) == 1,
              keySafetyFeature: (r['is_key_safety'] as int) == 1,
              displayOrder: r['display_order'] as int,
            ))
        .toList();

    return PrestartCheck(title: title, questions: questions);
  }

  @override
  Future<int> submitCheck(PrestartSubmission submission) async {
    final answers = <Map<String, Object?>>[];
    for (final q in submission.questions) {
      final r = submission.responses[q.id];
      if (r == null) continue;
      answers.add({
        'question_id': q.id,
        'category': q.category,
        'question': q.question,
        'answer': r.answer,
        'comment': r.comment,
        'is_correct': r.answer == q.correctAnswer,
        'is_key_safety': q.keySafetyFeature,
      });
    }

    return _db.insert('prestart_submissions', {
      'card_no': submission.cardNo,
      'user_name': submission.userName,
      'submitted_at': submission.submittedAt.toIso8601String(),
      'check_title': submission.checkTitle,
      'total_questions': submission.totalQuestions,
      'answered_count': submission.answeredCount,
      'all_correct': submission.allCorrect ? 1 : 0,
      'answers_json': jsonEncode(answers),
    });
  }
}
