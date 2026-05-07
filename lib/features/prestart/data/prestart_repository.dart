import 'package:rfid_scanner_app/features/prestart/domain/prestart_check.dart';
import 'package:rfid_scanner_app/features/prestart/domain/prestart_submission.dart';

/// Prestart data source.
///
/// **Integration boundary.** The production app should provide an
/// implementation of this interface and inject it at the top of the widget
/// tree, replacing the dummy `SqlitePrestartRepository` used during
/// development.
///
/// Kept narrow on purpose: load the current check, persist a submission.
abstract class PrestartRepository {
  /// Load the current prestart inspection: title + ordered list of questions.
  Future<PrestartCheck> loadCheck();

  /// Persist a submitted prestart check. Returns an opaque submission id
  /// (useful for an audit log; the integrating app may ignore it).
  Future<int> submitCheck(PrestartSubmission submission);
}
