/// One question in the prestart inspection.
class PrestartQuestion {
  const PrestartQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.correctAnswer,
    required this.required,
    required this.keySafetyFeature,
    required this.displayOrder,
  });

  final int id;
  final String category;
  final String question;

  /// `'yes'` or `'no'` — what the operator must answer for the check to pass.
  final String correctAnswer;

  /// Required questions must be answered for the check to be considered
  /// complete. Non-required ones can be skipped.
  final bool required;

  /// Marked as a key safety feature. Surfaced visually with a warning badge;
  /// failures here typically mean the vehicle should not be operated.
  final bool keySafetyFeature;

  /// Order in which the question is presented. Preserved from the source data.
  final int displayOrder;
}
