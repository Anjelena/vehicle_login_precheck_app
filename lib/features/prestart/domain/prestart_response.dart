/// The operator's response to a single prestart question.
class PrestartResponse {
  const PrestartResponse({required this.answer, this.comment});

  /// `'yes'` or `'no'`.
  final String answer;

  /// Optional free-text note. Trimmed; treated as absent when empty.
  final String? comment;

  bool get hasComment => comment != null && comment!.isNotEmpty;
}
