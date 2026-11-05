import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/widgets/busy_overlay.dart';

void main() {
  late BuildContext appContext;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            appContext = context;
            return const Scaffold(body: Text('home'));
          },
        ),
      ),
    );
  }

  final overlay = find.byKey(const ValueKey('busy_overlay'));

  testWidgets('shows only after the task signals, and hides when it finishes', (tester) async {
    await pumpApp(tester);
    final picked = Completer<void>();
    final converted = Completer<String>();
    late VoidCallback show;

    final result = BusyOverlay.during<String>(
      appContext,
      message: 'Importing photo…',
      task: (showBusy) async {
        show = showBusy;
        await picked.future;
        return converted.future;
      },
    );
    await tester.pump();
    expect(overlay, findsNothing, reason: 'hidden while the picker is open');

    show();
    picked.complete();
    await tester.pump();
    expect(overlay, findsOneWidget);
    expect(find.text('Importing photo…'), findsOneWidget);

    converted.complete('done');
    expect(await result, 'done');
    await tester.pump();
    expect(overlay, findsNothing);
  });

  testWidgets('hides when the task fails, and the error reaches the caller', (tester) async {
    await pumpApp(tester);

    Object? error;
    await BusyOverlay.during<void>(
      appContext,
      message: 'Importing image…',
      task: (showBusy) async {
        showBusy();
        showBusy(); // a second signal does not stack another overlay
        throw const FormatException('unsupported');
      },
    ).catchError((Object e) => error = e);
    await tester.pump();

    expect(error, isA<FormatException>());
    expect(overlay, findsNothing);
  });

  testWidgets('blocks taps on the app while shown', (tester) async {
    await pumpApp(tester);
    final done = Completer<void>();
    final result = BusyOverlay.during<void>(
      appContext,
      message: 'Importing logo…',
      task: (showBusy) {
        showBusy();
        return done.future;
      },
    );
    await tester.pump();

    expect(find.byType(ModalBarrier), findsWidgets);
    expect(overlay, findsOneWidget);

    done.complete();
    await result;
    await tester.pump();
  });
}
