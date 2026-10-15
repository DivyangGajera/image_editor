import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_edit_sheet.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('TextEditSheet Modal Tests', () {
    const initialLayer = TextLayer(
      id: 'layer-edit-1',
      x: 0.5,
      y: 0.5,
      text: 'Original Text',
      fontFamily: 'Roboto',
      fontSize: 28.0,
      textColorValue: 0xFFFFFFFF,
      isBold: false,
      isItalic: false,
    );

    Widget createTestApp({
      TextLayer? layer = initialLayer,
      ValueChanged<TextLayer>? onSaved,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      TextEditSheet.show(
                        context,
                        initialLayer: layer,
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('renders initial layer values in controls and live preview', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Title & Action buttons
      expect(find.text('Edit Text'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const ValueKey('text_edit_done_button')), findsOneWidget);

      // Text field has initial text
      expect(find.widgetWithText(TextField, 'Original Text'), findsOneWidget);

      // Font chips are visible
      expect(find.byKey(const ValueKey('font_chip_Roboto')), findsOneWidget);
      expect(find.byKey(const ValueKey('font_chip_Inter')), findsOneWidget);

      // Font size slider is present
      expect(find.byKey(const ValueKey('font_size_slider')), findsOneWidget);
      expect(find.text('28 pt'), findsOneWidget);
    });

    testWidgets('editing text and selecting font updates layer model', (tester) async {
      TextLayer? resultLayer;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        resultLayer = await TextEditSheet.show(
                          context,
                          initialLayer: initialLayer,
                        );
                      },
                      child: const Text('Open Sheet'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter new text
      final textInput = find.byKey(const ValueKey('text_input_field'));
      await tester.enterText(textInput, 'New Artwork Title');
      await tester.pumpAndSettle();

      // Select Inter font chip
      final interChip = find.byKey(const ValueKey('font_chip_Inter'));
      await tester.tap(interChip);
      await tester.pumpAndSettle();

      // Toggle Bold
      await tester.tap(find.byKey(const ValueKey('bold_toggle_button')));
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.byKey(const ValueKey('text_edit_done_button')));
      await tester.pumpAndSettle();

      // Sheet dismissed and returned updated layer
      expect(find.byType(TextEditSheet), findsNothing);
      expect(resultLayer, isNotNull);
      expect(resultLayer!.text, 'New Artwork Title');
      expect(resultLayer!.fontFamily, 'Inter');
      expect(resultLayer!.isBold, isTrue);
    });

    testWidgets('toggling background box enables box color and corner radius', (tester) async {
      TextLayer? resultLayer;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        resultLayer = await TextEditSheet.show(
                          context,
                          initialLayer: initialLayer,
                        );
                      },
                      child: const Text('Open Sheet'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Scroll main ListView down to reveal background box switch
      await tester.drag(find.byType(ListView).first, const Offset(0.0, -300.0));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const ValueKey('background_box_switch'));
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Scroll further down to reveal corner radius slider
      await tester.drag(find.byType(ListView).first, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();

      final sliderFinder = find.byKey(const ValueKey('box_border_radius_slider'));
      expect(sliderFinder, findsOneWidget);

      // Tap Done
      await tester.tap(find.byKey(const ValueKey('text_edit_done_button')));
      await tester.pumpAndSettle();

      expect(resultLayer, isNotNull);
      expect(resultLayer!.boxColorValue, isNotNull);
      expect(resultLayer!.boxBorderRadius, 8.0);
    });

    testWidgets('tapping Cancel dismisses modal without modifying layer', (tester) async {
      TextLayer? resultLayer = initialLayer;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        resultLayer = await TextEditSheet.show(
                          context,
                          initialLayer: initialLayer,
                        );
                      },
                      child: const Text('Open Sheet'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Modify text
      await tester.enterText(find.byKey(const ValueKey('text_input_field')), 'Draft Text');
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TextEditSheet), findsNothing);
      expect(resultLayer, isNull);
    });
  });
}
