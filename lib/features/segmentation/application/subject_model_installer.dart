import 'package:flutter/services.dart';
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

/// Makes sure the ML Kit subject segmentation model is installed.
///
/// Install-time model download only happens for Play Store installs; on
/// sideloaded APKs the model must be requested explicitly, which this does
/// through Google Play services' module installer (see MainActivity).
abstract interface class SubjectModelInstaller {
  Future<SubjectModelStatus> ensureModel();
}

/// [SubjectModelInstaller] talking to MainActivity over a method channel.
class PlayServicesModelInstaller implements SubjectModelInstaller {
  const PlayServicesModelInstaller();

  static const MethodChannel _channel = MethodChannel('chitred/ml_models');

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
}

/// App-wide [SubjectModelInstaller]; overridden in tests.
@Riverpod(keepAlive: true)
SubjectModelInstaller subjectModelInstaller(Ref ref) => const PlayServicesModelInstaller();
