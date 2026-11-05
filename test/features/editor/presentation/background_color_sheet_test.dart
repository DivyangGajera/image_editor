import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/editor/presentation/widgets/background_color_sheet.dart';

void main() {
  test('hex helpers convert between ARGB and RRGGBB', () {
    expect(BackgroundColorSheet.hexOf(0xFF3B82F6), '3B82F6');
    expect(BackgroundColorSheet.parseHex('#3b82f6'), 0xFF3B82F6);
    expect(BackgroundColorSheet.parseHex('12345'), isNull);
    expect(BackgroundColorSheet.parseHex('GGGGGG'), isNull);
  });

  Future<int?> pickWith(WidgetTester tester, Future<void> Function() interact) async {
    int? result;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await BackgroundColorSheet.show(context, initialColor: 0xFFFFFFFF),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await interact();
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('tapping a preset returns it', (tester) async {
    final result = await pickWith(tester, () async {
      await tester.tap(find.byKey(const ValueKey('bg_preset_000000')));
    });
    expect(result, 0xFF000000);
  });

  testWidgets('a custom hex color can be applied', (tester) async {
    final result = await pickWith(tester, () async {
      await tester.tap(find.byKey(const ValueKey('bg_custom_toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('bg_hex')), '12AB34');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('bg_custom_apply')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bg_custom_apply')));
    });
    expect(result, 0xFF12AB34);
  });
}
