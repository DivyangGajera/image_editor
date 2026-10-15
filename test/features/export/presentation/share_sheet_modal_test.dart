import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/export/presentation/widgets/share_sheet_modal.dart';

void main() {
  group('ShareSheetModal', () {
    testWidgets('renders export completion status and file path', (tester) async {
      const testPath = '/storage/emulated/0/Pictures/Exports/test_export.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareSheetModal(savedFilePath: testPath),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Complete!'), findsOneWidget);
      expect(find.text('Saved to your local gallery / pictures directory'), findsOneWidget);
      expect(find.text(testPath), findsOneWidget);
      expect(find.byKey(const ValueKey('share_sheet_done_button')), findsOneWidget);
    });

    testWidgets('tapping Done dismisses modal', (tester) async {
      const testPath = '/mock/Pictures/export.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShareSheetModal.show(context, savedFilePath: testPath),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Export Complete!'), findsOneWidget);

      // Tap Done button
      await tester.tap(find.byKey(const ValueKey('share_sheet_done_button')));
      await tester.pumpAndSettle();

      // Modal dismissed
      expect(find.text('Export Complete!'), findsNothing);
    });
  });
}
