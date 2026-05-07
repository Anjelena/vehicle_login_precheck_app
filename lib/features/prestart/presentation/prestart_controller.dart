import 'package:flutter/foundation.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/features/prestart/data/prestart_repository.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_check.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_question.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_response.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_submission.dart';

/// State + actions for the prestart inspection screen.
///
/// Loads the check from the [PrestartRepository], tracks the operator's
/// per-question responses, exposes validation, and submits the completed
/// inspection back through the repository.
class PrestartController extends ChangeNotifier {
  PrestartController({
    required this.repository,
    required this.session,
  });

  final PrestartRepository repository;
  final Session session;

  PrestartCheck? _check;
  final Map<int, PrestartResponse> _responses = {};
  bool _isLoading = true;
  String? _errorMessage;

  String get title => _check?.title ?? 'Prestart Check';
  List<PrestartQuestion> get questions => _check?.questions ?? const [];
  Map<int, PrestartResponse> get responses => Map.unmodifiable(_responses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get answeredCount => _responses.length;
  int get totalQuestions => questions.length;
  int get requiredCount => questions.where((q) => q.required).length;

  bool get allRequiredAnswered => questions
      .where((q) => q.required)
      .every((q) => _responses.containsKey(q.id));

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _check = await repository.loadCheck();
      AppLogger.i('Loaded ${_check!.questions.length} prestart questions');
    } catch (e) {
      AppLogger.e('Failed to load prestart questions: $e');
      _errorMessage = 'Failed to load questions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void answerQuestion(int questionId, String answer) {
    final existing = _responses[questionId];
    _responses[questionId] = PrestartResponse(
      answer: answer,
      comment: existing?.comment,
    );
    notifyListeners();
  }

  void updateComment(int questionId, String comment) {
    final existing = _responses[questionId];
    if (existing == null) return;
    final trimmed = comment.trim();
    _responses[questionId] = PrestartResponse(
      answer: existing.answer,
      comment: trimmed.isEmpty ? null : trimmed,
    );
    notifyListeners();
  }

  String? getAnswer(int questionId) => _responses[questionId]?.answer;
  String? getComment(int questionId) => _responses[questionId]?.comment;
  bool isAnswered(int questionId) => _responses.containsKey(questionId);
  bool hasComment(int questionId) =>
      _responses[questionId]?.hasComment ?? false;
  bool isAnswerCorrect(PrestartQuestion q) =>
      _responses[q.id]?.answer == q.correctAnswer;

  /// Returns every answered question whose answer is wrong OR has a
  /// non-empty comment (the operator flagged it for follow-up).
  List<QuestionWithIssue> getQuestionsWithIssues() {
    final out = <QuestionWithIssue>[];
    for (final q in questions) {
      final r = _responses[q.id];
      if (r == null) continue;
      final correct = r.answer == q.correctAnswer;
      if (!correct || r.hasComment) {
        out.add(QuestionWithIssue(
          question: q,
          response: r,
          isCorrect: correct,
        ));
      }
    }
    return out;
  }

  CheckValidation validate() {
    final required = questions.where((q) => q.required).toList();
    final unanswered =
        required.where((q) => !_responses.containsKey(q.id)).toList();
    return CheckValidation(
      isComplete: allRequiredAnswered,
      answeredCount: answeredCount,
      totalCount: totalQuestions,
      unansweredRequired: unanswered,
      questionsWithIssues: getQuestionsWithIssues(),
    );
  }

  /// Persist the current responses as a submission. Throws if no user is
  /// logged in.
  Future<int> submit() async {
    final user = session.user;
    if (user == null) {
      throw StateError('Cannot submit prestart: no authenticated user');
    }
    final submission = PrestartSubmission(
      cardNo: user.cardNo,
      userName: user.name,
      submittedAt: DateTime.now(),
      checkTitle: title,
      questions: questions,
      responses: Map.unmodifiable(_responses),
    );
    final id = await repository.submitCheck(submission);
    AppLogger.i(
        'Saved prestart submission id=$id for ${user.name} (cardNo=${user.cardNo})');
    return id;
  }

  void resetForm() {
    _responses.clear();
    notifyListeners();
  }
}

/// Result of validating the current prestart state.
class CheckValidation {
  const CheckValidation({
    required this.isComplete,
    required this.answeredCount,
    required this.totalCount,
    required this.unansweredRequired,
    required this.questionsWithIssues,
  });

  /// True when every required question has been answered (regardless of
  /// whether the answer is correct).
  final bool isComplete;
  final int answeredCount;
  final int totalCount;
  final List<PrestartQuestion> unansweredRequired;
  final List<QuestionWithIssue> questionsWithIssues;
}

/// A question with either an incorrect answer or a flagged comment.
class QuestionWithIssue {
  const QuestionWithIssue({
    required this.question,
    required this.response,
    required this.isCorrect,
  });

  final PrestartQuestion question;
  final PrestartResponse response;
  final bool isCorrect;
}
