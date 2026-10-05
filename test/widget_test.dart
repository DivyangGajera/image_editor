import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/main.dart';

void main() {
  testWidgets('OfflineImageEditorApp root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OfflineImageEditorApp(),
      ),
    );

    // Verify app title in AppBar and initial canvas placeholder text
    expect(find.text(AppConstants.appTitle), findsOneWidget);
    expect(find.text('Offline Canvas Ready'), findsOneWidget);
  });
}
