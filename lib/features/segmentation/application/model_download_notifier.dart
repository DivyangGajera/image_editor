import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_editor/core/network/internet_check.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_download_notifier.g.dart';

/// Where the background-remover model download stands.
@immutable
sealed class ModelDownloadState {
  const ModelDownloadState();
}

/// Checking the internet connection before downloading.
final class ModelDownloadChecking extends ModelDownloadState {
  const ModelDownloadChecking();
}

/// No internet: the user must turn on mobile data or Wi-Fi.
final class ModelDownloadOffline extends ModelDownloadState {
  const ModelDownloadOffline();
}

/// Downloading; [progress] is null until Play services reports any.
final class ModelDownloadInProgress extends ModelDownloadState {
  const ModelDownloadInProgress([this.progress]);
  final ModelDownloadProgress? progress;

  @override
  bool operator ==(Object other) => other is ModelDownloadInProgress && other.progress == progress;

  @override
  int get hashCode => progress.hashCode;
}

/// The model is installed.
final class ModelDownloadCompleted extends ModelDownloadState {
  const ModelDownloadCompleted();
}

/// The download failed; [detail] is the technical cause.
final class ModelDownloadFailed extends ModelDownloadState {
  const ModelDownloadFailed(this.detail);
  final String detail;

  @override
  bool operator ==(Object other) => other is ModelDownloadFailed && other.detail == detail;

  @override
  int get hashCode => detail.hashCode;
}

/// Downloads the background-remover model on request, checking the internet
/// first. Disposed (and the progress subscription cancelled) when the
/// download dialog closes; Play services finishes a started download anyway.
@riverpod
class ModelDownloadNotifier extends _$ModelDownloadNotifier {
  late InternetCheck _internet;
  late SubjectModelInstaller _installer;
  StreamSubscription<ModelDownloadProgress>? _subscription;

  @override
  ModelDownloadState build() {
    _internet = ref.watch(internetCheckProvider);
    _installer = ref.watch(subjectModelInstallerProvider);
    ref.onDispose(() => _subscription?.cancel());
    return const ModelDownloadChecking();
  }

  /// Checks the connection and, when online, starts the download. Also used
  /// to retry after going offline or a failure.
  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = null;
    state = const ModelDownloadChecking();

    final online = await _internet.isOnline();
    if (!ref.mounted) return;
    if (!online) {
      state = const ModelDownloadOffline();
      return;
    }

    state = const ModelDownloadInProgress();
    _subscription = _installer.download().listen(
      (progress) {
        if (ref.mounted) state = ModelDownloadInProgress(progress);
      },
      onError: (Object error) {
        if (!ref.mounted) return;
        state = ModelDownloadFailed(error is SubjectModelException ? error.detail : error.toString());
      },
      onDone: () {
        if (ref.mounted && state is! ModelDownloadFailed) state = const ModelDownloadCompleted();
      },
      cancelOnError: true,
    );
  }
}
