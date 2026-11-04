import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/domain/font_catalog.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_layer_widget.dart';

import '../../../helpers/fixed_font_library.dart';

void main() {

  group('TextLayerWidget Presentation Tests', () {
    Widget createTestApp(TextLayer layer, {List<String> installed = const []}) {
      return ProviderScope(
        overrides: [fontLibraryProvider.overrideWith(() => FixedFontLibrary(installed))],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextLayerWidget(layer: layer),
            ),
          ),
        ),
      );
    }

    testWidgets('renders basic text content with default styling', (tester) async {
      const layer = TextLayer(
        id: 'layer-text-1',
        x: 0.5,
        y: 0.5,
        text: 'Typography Header',
      );

      await tester.pumpWidget(createTestApp(layer));
      await tester.pumpAndSettle();

      final textFinder = find.text('Typography Header');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontSize, 24.0);
      expect(textWidget.style?.color, const Color(0xFFFFFFFF));
      expect(textWidget.style?.fontWeight, FontWeight.normal);
      expect(textWidget.style?.fontStyle, FontStyle.normal);
      expect(textWidget.style?.shadows, isNull);
    });

    testWidgets('renders customized bold, italic, and colored text', (tester) async {
      const layer = TextLayer(
        id: 'layer-text-2',
        x: 0.5,
        y: 0.5,
        text: 'Styled Header',
        fontSize: 36.0,
        textColorValue: 0xFFFF5722, // Deep Coral
        isBold: true,
        isItalic: true,
      );

      await tester.pumpWidget(createTestApp(layer));
      await tester.pumpAndSettle();

      final textFinder = find.text('Styled Header');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontSize, 36.0);
      expect(textWidget.style?.color, const Color(0xFFFF5722));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('renders drop shadow when shadowColorValue is specified', (tester) async {
      const layer = TextLayer(
        id: 'layer-text-3',
        x: 0.5,
        y: 0.5,
        text: 'Shadow Text',
        shadowColorValue: 0xFF000000,
      );

      await tester.pumpWidget(createTestApp(layer));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Shadow Text'));
      expect(textWidget.style?.shadows, isNotNull);
      expect(textWidget.style!.shadows!.length, 1);
      expect(textWidget.style!.shadows!.first.color, const Color(0xFF000000));
      expect(textWidget.style!.shadows!.first.blurRadius, 4.0);
    });

    testWidgets('renders background box with specified color and border radius', (tester) async {
      const layer = TextLayer(
        id: 'layer-text-4',
        x: 0.5,
        y: 0.5,
        text: 'Badge Text',
        boxColorValue: 0xFF1E293B,
        boxBorderRadius: 12.0,
      );

      await tester.pumpWidget(createTestApp(layer));
      await tester.pumpAndSettle();

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Find container that has decoration with 0xFF1E293B
      final matchingContainer = tester.widgetList<Container>(containerFinder).firstWhere(
        (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color == const Color(0xFF1E293B),
      );

      final decoration = matchingContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF1E293B));
      expect(decoration.borderRadius, BorderRadius.circular(12.0));
      expect(matchingContainer.padding, const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0));
    });

    testWidgets('an installed font is applied without a missing badge', (tester) async {
      await tester.pumpWidget(createTestApp(
        const TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Sale', fontFamily: 'Anton'),
        installed: ['Anton'],
      ));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text('Sale')).style?.fontFamily, 'Anton');
      expect(find.byKey(const ValueKey('missing_font_badge')), findsNothing);
    });

    testWidgets('a deleted font falls back to the default and shows the badge', (tester) async {
      await tester.pumpWidget(createTestApp(
        const TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Sale', fontFamily: 'Anton'),
      ));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text('Sale')).style?.fontFamily, isNull);
      expect(find.byKey(const ValueKey('missing_font_badge')), findsOneWidget);
    });

    testWidgets('the built-in default never shows the badge', (tester) async {
      await tester.pumpWidget(createTestApp(
        const TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Sale', fontFamily: systemDefaultFontFamily),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('missing_font_badge')), findsNothing);
    });
  });
}
