import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/projects/presentation/edited_label.dart';

void main() {
  final now = DateTime(2026, 11, 4, 15, 30);

  test('recent edits use minutes and hours', () {
    expect(editedLabel(now.subtract(const Duration(seconds: 20)), now), 'Edited just now');
    expect(editedLabel(now.subtract(const Duration(minutes: 5)), now), 'Edited 5 min ago');
    expect(editedLabel(now.subtract(const Duration(hours: 3)), now), 'Edited 3 h ago');
  });

  test('older edits use calendar days, then the date', () {
    expect(editedLabel(DateTime(2026, 11, 3, 23, 50), now), 'Edited yesterday');
    expect(editedLabel(DateTime(2026, 11, 1, 9), now), 'Edited 3 days ago');
    expect(editedLabel(DateTime(2026, 10, 12, 9), now), 'Edited 12 Oct 2026');
  });
}
