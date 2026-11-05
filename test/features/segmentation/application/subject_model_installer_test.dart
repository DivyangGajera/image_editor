import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('chitred/ml_models');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void answer(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async => handler(call));
  }

  test('isAvailable reports what Play services says', () async {
    answer((call) => call.method == 'isSubjectSegmentationModelAvailable' ? false : null);
    expect(await const PlayServicesModelInstaller().isAvailable(), isFalse);

    answer((call) => true);
    expect(await const PlayServicesModelInstaller().isAvailable(), isTrue);
  });

  test('a failing availability check does not block removal', () async {
    answer((call) => throw PlatformException(code: 'MODEL_CHECK_FAILED', message: 'API unavailable'));
    expect(await const PlayServicesModelInstaller().isAvailable(), isTrue);
  });

  test('without the platform channel the model counts as available', () async {
    expect(await const PlayServicesModelInstaller().isAvailable(), isTrue);
  });

  test('progress events are parsed, with an unknown size as no fraction', () {
    final progress = PlayServicesModelInstaller.progressFromEvent({'downloaded': 300, 'total': 1200});
    expect(progress, const ModelDownloadProgress(downloadedBytes: 300, totalBytes: 1200));
    expect(progress.fraction, 0.25);

    final unknown = PlayServicesModelInstaller.progressFromEvent({'downloaded': 0, 'total': 0});
    expect(unknown.fraction, isNull);
    expect(PlayServicesModelInstaller.progressFromEvent(null).totalBytes, 0);
  });
}
