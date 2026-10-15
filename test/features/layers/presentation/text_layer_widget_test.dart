import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_layer_widget.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('TextLayerWidget Presentation Tests', () {
    Widget createTestApp(TextLayer layer) {
      return ProviderScope(
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
  });
}
