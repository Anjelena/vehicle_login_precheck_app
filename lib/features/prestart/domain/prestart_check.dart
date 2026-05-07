import 'package:rfid_scanner_app/features/prestart/domain/prestart_question.dart';

/// A loaded prestart inspection — the title plus an ordered list of questions.
class PrestartCheck {
  const PrestartCheck({required this.title, required this.questions});

  final String title;
  final List<PrestartQuestion> questions;
}
