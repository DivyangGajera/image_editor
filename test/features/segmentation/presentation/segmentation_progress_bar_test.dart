import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';
import 'package:image_editor/features/segmentation/presentation/widgets/segmentation_progress_bar.dart';

void main() {
  group('SegmentationProgressBar', () {
    testWidgets('renders SizedBox.shrink when not processing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SegmentationProgressBar(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('segmentation_progress_bar')),
        findsNothing,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('renders progress bar and default message when processing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            segmentationNotifierProvider.overrideWith(() => _ProcessingNotifier(
                  const SegmentationState(isProcessing: true),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SegmentationProgressBar(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('segmentation_progress_bar')),
        findsOneWidget,
      );
      expect(find.text('Extracting background...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders custom message and percentage when progress is provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            segmentationNotifierProvider.overrideWith(() => _ProcessingNotifier(
                  const SegmentationState(isProcessing: true, progress: 0.72),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SegmentationProgressBar(
                message: 'Isolating portrait...',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Isolating portrait...'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}

class _ProcessingNotifier extends Notifier<SegmentationState>
    implements SegmentationNotifier {
  _ProcessingNotifier(this._initialState);

  final SegmentationState _initialState;

  @override
  SegmentationState build() => _initialState;

  @override
  void clearError() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
