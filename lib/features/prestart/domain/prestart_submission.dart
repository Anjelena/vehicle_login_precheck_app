import 'package:rfid_scanner_app/features/prestart/domain/prestart_question.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_response.dart';

/// A completed prestart check ready to be persisted.
///
/// Carries [questions] alongside [responses] so the audit log can capture the
/// question text and category as they were *at the time of submission* — even
/// if the questions table changes later.
class PrestartSubmission {
  const PrestartSubmission({
    required this.cardNo,
    required this.userName,
    required this.submittedAt,
    required this.checkTitle,
    required this.questions,
    required this.responses,
  });

  final int cardNo;
  final String userName;
  final DateTime submittedAt;
  final String checkTitle;
  final List<PrestartQuestion> questions;
  final Map<int, PrestartResponse> responses;

  int get totalQuestions => questions.length;
  int get answeredCount => responses.length;

  /// True when every question has a response and each response matches the
  /// question's `correctAnswer`.
  bool get allCorrect => questions.every((q) {
    final r = responses[q.id];
    return r != null && r.answer == q.correctAnswer;
  });
}
