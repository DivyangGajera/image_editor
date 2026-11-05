import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subject_model_installer.g.dart';

/// Availability of the on-device subject segmentation model.
enum SubjectModelStatus {
  /// Ready to use.
  available,

  /// Google Play services is downloading it.
  installing,
}

/// Thrown when Google Play services cannot provide the model.
class SubjectModelException implements Exception {
  const SubjectModelException(this.detail);
  final String detail;

  @override
  String toString() => 'SubjectModelException: $detail';
}

/// Progress of a model download, as reported by Google Play services.
@immutable
class ModelDownloadProgress {
  const ModelDownloadProgress({required this.downloadedBytes, required this.totalBytes});

  final int downloadedBytes;

  /// Total download size, or 0 while it is not known yet.
  final int totalBytes;

  /// Completed fraction (0–1), or null while the size is unknown.
  double? get fraction =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0).toDouble() : null;

  @override
  bool operator ==(Object other) =>
      other is ModelDownloadProgress &&
      other.downloadedBytes == downloadedBytes &&
      other.totalBytes == totalBytes;

  @override
  int get hashCode => Object.hash(downloadedBytes, totalBytes);
}

/// Makes sure the ML Kit subject segmentation model is installed.
///
/// Install-time model download only happens for Play Store installs; on
/// sideloaded APKs the model must be requested explicitly, which this does
/// through Google Play services' module installer (see MainActivity).
abstract interface class SubjectModelInstaller {
  /// Requests the model in the background (used at app start).
  Future<SubjectModelStatus> ensureModel();

  /// Whether the model is installed and background removal can run now.
  Future<bool> isAvailable();

  /// Downloads the model, emitting progress. The stream completes when the
  /// model is installed and fails with a [SubjectModelException] otherwise.
  Stream<ModelDownloadProgress> download();
}

/// [SubjectModelInstaller] talking to MainActivity over platform channels.
class PlayServicesModelInstaller implements SubjectModelInstaller {
  const PlayServicesModelInstaller();

  static const MethodChannel _channel = MethodChannel('chitred/ml_models');
  static const EventChannel _downloadChannel = EventChannel('chitred/ml_models/download');

  @override
  Future<SubjectModelStatus> ensureModel() async {
    try {
      final status = await _channel.invokeMethod<String>('ensureSubjectSegmentationModel');
      return status == 'installing' ? SubjectModelStatus.installing : SubjectModelStatus.available;
    } on MissingPluginException {
      // Not on Android (e.g. tests): let ML Kit itself report problems.
      return SubjectModelStatus.available;
    } on PlatformException catch (error) {
      throw SubjectModelException('${error.code}: ${error.message}');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isSubjectSegmentationModelAvailable') ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException catch (error) {
      // The check itself failing must not block removal: ML Kit may still
      // work, and reports its own error if it does not.
      AppLogger.warning('Model availability check failed: ${error.code} ${error.message}', tag: 'Segmentation');
      return true;
    }
  }

  @override
  Stream<ModelDownloadProgress> download() {
    return _downloadChannel.receiveBroadcastStream().map(progressFromEvent).handleError(
      (Object error) {
        if (error is PlatformException) {
          throw SubjectModelException('${error.code}: ${error.message}');
        }
        throw SubjectModelException(error.toString());
      },
    );
  }

  /// Parses a progress event sent by MainActivity.
  @visibleForTesting
  static ModelDownloadProgress progressFromEvent(Object? event) {
    final map = event is Map ? event : const <Object?, Object?>{};
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return ModelDownloadProgress(downloadedBytes: read('downloaded'), totalBytes: read('total'));
  }
}

/// App-wide [SubjectModelInstaller]; overridden in tests.
@Riverpod(keepAlive: true)
SubjectModelInstaller subjectModelInstaller(Ref ref) => const PlayServicesModelInstaller();
