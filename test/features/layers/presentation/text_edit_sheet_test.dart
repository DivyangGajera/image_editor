import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/domain/font_catalog.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_edit_sheet.dart';

import '../../../helpers/fixed_font_library.dart';

void main() {
  TextLayer? result;
  var resultReceived = false;

  Future<void> openSheet(
    WidgetTester tester, {
    TextLayer? initial,
    List<String> installedFonts = const ['Anton'],
  }) async {
    result = null;
    resultReceived = false;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [fontLibraryProvider.overrideWith(() => FixedFontLibrary(installedFonts))],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await TextEditSheet.show(context, initialLayer: initial);
                  resultReceived = true;
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  const existing = TextLayer(
    id: 'existing',
    x: 0.3,
    y: 0.7,
    scale: 2.0,
    rotation: 0.4,
    zIndex: 3,
    text: 'Original Text',
    fontSize: 40.0,
  );

  testWidgets('new text starts with readable defaults and a live preview', (tester) async {
    await openSheet(tester);

    expect(find.text('Add Text'), findsOneWidget);
    expect(find.byKey(const ValueKey('text_preview')), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('28 pt'), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('text_edit_done_button')));

    expect(result, isNotNull);
    expect(result!.text, 'Your text');
    expect(result!.fontFamily, systemDefaultFontFamily);
    expect(result!.isCustomFont, isFalse);
    expect(result!.textColorValue, 0xFF000000, reason: 'black text on the white canvas');
  });

  testWidgets('editing keeps the layer identity and transform', (tester) async {
    await openSheet(tester, initial: existing);

    expect(find.text('Edit Text'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Original Text'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('text_input_field')), 'Big Sale');
    await tapVisible(tester, find.byKey(const ValueKey('bold_toggle_button')));
    await tapVisible(tester, find.byKey(const ValueKey('text_color_${0xFFEF4444}')));
    await tapVisible(tester, find.byKey(const ValueKey('text_edit_done_button')));

    expect(result!.id, 'existing');
    expect(result!.x, 0.3);
    expect(result!.scale, 2.0);
    expect(result!.rotation, 0.4);
    expect(result!.zIndex, 3);
    expect(result!.text, 'Big Sale');
    expect(result!.isBold, isTrue);
    expect(result!.textColorValue, 0xFFEF4444);
  });

  testWidgets('the font row opens the picker and applies the chosen font', (tester) async {
    await openSheet(tester);

    await tapVisible(tester, find.byKey(const ValueKey('font_picker_row')));
    expect(find.text('Fonts'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('font_row_Anton')));

    expect(find.descendant(
      of: find.byKey(const ValueKey('font_picker_row')),
      matching: find.text('Anton'),
    ), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('text_edit_done_button')));
    expect(result!.fontFamily, 'Anton');
    expect(result!.isCustomFont, isTrue);
    expect(result!.customFontPath, startsWith('fonts/'));
  });

  testWidgets('a font that is not installed is labelled and explained', (tester) async {
    await openSheet(
      tester,
      initial: existing.copyWith(fontFamily: 'Poppins'),
      installedFonts: const [],
    );

    expect(find.text('Poppins (not installed)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('background_box_switch')));
    expect(
      find.text('This text shows in the default font until its font is installed.'),
      findsOneWidget,
    );
  });

  testWidgets('the background box reveals its colors and corner radius', (tester) async {
    await openSheet(tester);

    expect(find.byKey(const ValueKey('box_border_radius_slider')), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('background_box_switch')));
    // The list builds lazily: scroll down to the newly revealed controls.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('box_border_radius_slider')),
      200.0,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('box_border_radius_slider')), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('box_color_${0xFF3B82F6}')));
    await tapVisible(tester, find.byKey(const ValueKey('text_edit_done_button')));
    expect(result!.boxColorValue, 0xFF3B82F6);
  });

  testWidgets('Cancel closes without a result', (tester) async {
    await openSheet(tester, initial: existing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resultReceived, isTrue);
    expect(result, isNull);
  });
}
