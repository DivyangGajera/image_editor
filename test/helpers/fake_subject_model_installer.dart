import 'dart:async';

import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';

/// Configurable [SubjectModelInstaller] for tests.
///
/// [download] returns [downloadController]'s stream, so tests push progress,
/// errors and completion themselves; [downloadStarts] counts the downloads.
class FakeSubjectModelInstaller implements SubjectModelInstaller {
  FakeSubjectModelInstaller({
    this.status = SubjectModelStatus.available,
    this.available = true,
    this.ensureFailure,
  });

  SubjectModelStatus status;
  bool available;
  String? ensureFailure;
  int downloadStarts = 0;
  // Closed by the tests that complete a download.
  // ignore: close_sinks
  StreamController<ModelDownloadProgress> downloadController =
      StreamController<ModelDownloadProgress>.broadcast();

  @override
  Future<SubjectModelStatus> ensureModel() async {
    final failure = ensureFailure;
    if (failure != null) throw SubjectModelException(failure);
    return status;
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<ModelDownloadProgress> download() {
    downloadStarts++;
    return downloadController.stream;
  }
}
