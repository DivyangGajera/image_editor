import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/network/internet_check.dart';
import 'package:image_editor/features/segmentation/application/model_download_notifier.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';

import '../../../helpers/fake_internet_check.dart';
import '../../../helpers/fake_subject_model_installer.dart';

void main() {
  late FakeInternetCheck internet;
  late FakeSubjectModelInstaller installer;
  late ProviderContainer container;
  late List<ModelDownloadState> states;

  setUp(() {
    internet = FakeInternetCheck();
    installer = FakeSubjectModelInstaller(available: false);
    container = ProviderContainer(
      overrides: [
        internetCheckProvider.overrideWithValue(internet),
        subjectModelInstallerProvider.overrideWithValue(installer),
      ],
    );
    states = [];
    container.listen(modelDownloadProvider, (_, next) => states.add(next), fireImmediately: true);
  });

  tearDown(() => container.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('offline: asks for internet and does not download', () async {
    internet.online = false;

    await container.read(modelDownloadProvider.notifier).start();

    expect(container.read(modelDownloadProvider), const ModelDownloadOffline());
    expect(installer.downloadStarts, 0);
  });

  test('online: reports progress, then completion', () async {
    await container.read(modelDownloadProvider.notifier).start();
    expect(container.read(modelDownloadProvider), const ModelDownloadInProgress());

    const half = ModelDownloadProgress(downloadedBytes: 512, totalBytes: 1024);
    installer.downloadController.add(half);
    await settle();
    expect(container.read(modelDownloadProvider), const ModelDownloadInProgress(half));
    expect(half.fraction, 0.5);

    await installer.downloadController.close();
    await settle();
    expect(container.read(modelDownloadProvider), const ModelDownloadCompleted());
    expect(installer.downloadStarts, 1);
  });

  test('a failed download keeps its detail, and Retry starts again', () async {
    final notifier = container.read(modelDownloadProvider.notifier);
    await notifier.start();

    installer.downloadController.addError(const SubjectModelException('MODEL_DOWNLOAD_FAILED: error 7'));
    await settle();
    expect(container.read(modelDownloadProvider), const ModelDownloadFailed('MODEL_DOWNLOAD_FAILED: error 7'));

    await notifier.start();
    expect(container.read(modelDownloadProvider), const ModelDownloadInProgress());
    expect(installer.downloadStarts, 2);
  });

  test('going back online after Retry downloads', () async {
    internet.online = false;
    final notifier = container.read(modelDownloadProvider.notifier);
    await notifier.start();
    internet.online = true;

    await notifier.start();

    expect(states, contains(const ModelDownloadOffline()));
    expect(container.read(modelDownloadProvider), const ModelDownloadInProgress());
  });
}
