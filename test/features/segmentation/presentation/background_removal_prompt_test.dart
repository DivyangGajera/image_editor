import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/presentation/background_removal_prompt.dart';
import 'package:mocktail/mocktail.dart';

class MockBackgroundRemovalService extends Mock implements BackgroundRemovalService {}

void main() {
  late MockBackgroundRemovalService service;
  Uint8List? result;
  var closed = false;

  final original = Uint8List.fromList(img.encodePng(img.Image(width: 10, height: 10)));
  final cutout = Uint8List.fromList(img.encodePng(img.Image(width: 10, height: 10, numChannels: 4)));

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  Future<void> openPrompt(WidgetTester tester) async {
    service = MockBackgroundRemovalService();
    result = null;
    closed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backgroundRemovalServiceProvider.overrideWithValue(service)],
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
}
