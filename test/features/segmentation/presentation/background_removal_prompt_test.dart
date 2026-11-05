import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/presentation/background_removal_prompt.dart';
import 'package:image_editor/core/network/internet_check.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_internet_check.dart';
import '../../../helpers/fake_subject_model_installer.dart';

class MockBackgroundRemovalService extends Mock implements BackgroundRemovalService {}

void main() {
  late MockBackgroundRemovalService service;
  late FakeSubjectModelInstaller installer;
  late FakeInternetCheck internet;
  Uint8List? result;
  var closed = false;

  final original = Uint8List.fromList(img.encodePng(img.Image(width: 10, height: 10)));
  final cutout = Uint8List.fromList(img.encodePng(img.Image(width: 10, height: 10, numChannels: 4)));

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  Future<void> openPrompt(WidgetTester tester, {bool modelInstalled = true}) async {
    service = MockBackgroundRemovalService();
    installer = FakeSubjectModelInstaller(available: modelInstalled);
    internet = FakeInternetCheck();
    result = null;
    closed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backgroundRemovalServiceProvider.overrideWithValue(service),
          subjectModelInstallerProvider.overrideWithValue(installer),
          internetCheckProvider.overrideWithValue(internet),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await BackgroundRemovalPrompt.show(context, imageBytes: original);
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Keep original returns null without running removal', (tester) async {
    await openPrompt(tester);

    await tester.tap(find.byKey(const ValueKey('prompt_keep_original')));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
    verifyNever(() => service.cutOut(any()));
  });

  testWidgets('Remove background shows the cut-out, which can be compared and used',
      (tester) async {
    await openPrompt(tester);
    when(() => service.cutOut(any())).thenAnswer((_) async => cutout);

    await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('prompt_cutout')), findsOneWidget);
    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('prompt_original')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('prompt_use_cutout')));
    await tester.pumpAndSettle();
    expect(result, cutout);
  });

  testWidgets('failures are explained and the original can still be kept', (tester) async {
    await openPrompt(tester);
    when(() => service.cutOut(any())).thenThrow(BackgroundRemovalException.noSubject);

    await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
    await tester.pumpAndSettle();

    expect(find.text(BackgroundRemovalException.noSubject.message), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('prompt_keep_original')));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('unexpected failures show their technical details', (tester) async {
    await openPrompt(tester);
    when(() => service.cutOut(any()))
        .thenThrow(BackgroundRemovalException.failed('mask has 7 values for a 10x10 image'));

    await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
    await tester.pumpAndSettle();

    expect(find.text('Details: mask has 7 values for a 10x10 image'), findsOneWidget);
  });

  testWidgets('going back keeps the original', (tester) async {
    await openPrompt(tester);

    await tester.tap(find.byTooltip('Keep original'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  group('when the background remover is not downloaded yet', () {
    testWidgets('"Not now" closes the offer and does nothing', (tester) async {
      await openPrompt(tester, modelInstalled: false);

      await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bg_model_offer')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bg_model_not_now')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bg_model_offer')), findsNothing);
      expect(installer.downloadStarts, 0);
      expect(internet.checks, 0);
      verifyNever(() => service.cutOut(any()));
      expect(closed, isFalse, reason: 'the prompt stays open');
    });

    testWidgets('Download shows size and progress, then says to tap again', (tester) async {
      await openPrompt(tester, modelInstalled: false);
      await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bg_model_download')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('bg_model_download_dialog')), findsOneWidget);

      installer.downloadController.add(
        const ModelDownloadProgress(downloadedBytes: 1024 * 1024, totalBytes: 4 * 1024 * 1024),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('bg_model_progress')), findsOneWidget);
      expect(find.text('1.0 MB of 4.0 MB'), findsOneWidget);
      expect(find.text('Downloading… 25%'), findsOneWidget);

      installer.available = true;
      await installer.downloadController.close();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bg_model_download_dialog')), findsNothing);
      expect(
        find.text('Background remover is ready. Tap Remove BG to cut out this image.'),
        findsOneWidget,
      );
      verifyNever(() => service.cutOut(any()));

      // Tapping again now removes the background.
      when(() => service.cutOut(any())).thenAnswer((_) async => cutout);
      await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('prompt_cutout')), findsOneWidget);
    });

    testWidgets('offline: asks to turn on the internet, and Retry downloads', (tester) async {
      await openPrompt(tester, modelInstalled: false);
      internet.online = false;
      await tester.tap(find.byKey(const ValueKey('prompt_remove_background')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bg_model_download')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bg_model_offline')), findsOneWidget);
      expect(installer.downloadStarts, 0);

      internet.online = true;
      await tester.tap(find.byKey(const ValueKey('bg_model_retry')));
      await tester.pump();
      await tester.pump();
      expect(installer.downloadStarts, 1);
      expect(find.text('Downloading…'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bg_model_cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bg_model_download_dialog')), findsNothing);
      expect(find.byKey(const ValueKey('bg_model_ready')), findsNothing);
    });
  });
}
