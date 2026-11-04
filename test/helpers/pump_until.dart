import 'package:flutter_test/flutter_test.dart';

/// Pumps frames, letting real (non-fake-async) I/O run between them, until
/// [condition] holds or about [timeout] passes; then fails with [reason].
///
/// Widget tests run in a fake-async zone, while Hive and file I/O complete in
/// real time. Fixed sleeps are flaky when the whole suite runs in parallel,
/// so tests wait for the outcome instead. Avoids pumpAndSettle while
/// polling, because progress spinners animate until the work is done.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String reason = 'condition not reached in time',
}) async {
  const step = Duration(milliseconds: 50);
  final rounds = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < rounds && !condition(); i++) {
    await tester.runAsync(() => Future<void>.delayed(step));
    await tester.pump(step);
  }
  expect(condition(), isTrue, reason: reason);
  await tester.pumpAndSettle();
}
