import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/tutorial/tutorial.dart';

import '../../helpers/memory_tutorial_repository.dart';

void main() {
  const tour = TourDefinition(
    id: 'demo',
    steps: [
      TourStep(anchorId: 'a', title: 'Step A', body: 'About A'),
      TourStep(anchorId: 'missing', title: 'Step Missing', body: 'Not on screen'),
      TourStep(anchorId: 'b', title: 'Step B', body: 'About B'),
      TourStep(anchorId: 'far', title: 'Step Far', body: 'About far away'),
    ],
  );

  late MemoryTutorialRepository repository;
  late ProviderContainer container;
  late int taps;

  Future<void> pumpApp(WidgetTester tester, {bool unseen = true}) async {
    repository = unseen ? MemoryTutorialRepository.unseen() : MemoryTutorialRepository();
    container = ProviderContainer(overrides: [tutorialRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    taps = 0;
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 60.0),
                Row(
                  children: [
                    TourAnchor(
                      id: 'a',
                      child: ElevatedButton(
                        key: const ValueKey('button_a'),
                        onPressed: () => taps++,
                        child: const Text('A'),
                      ),
                    ),
                    const SizedBox(width: 40.0),
                    TourAnchor(
                      id: 'b',
                      child: ElevatedButton(key: const ValueKey('button_b'), onPressed: () {}, child: const Text('B')),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 60.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 2500.0),
                        TourAnchor(
                          id: 'far',
                          child: ElevatedButton(
                            key: const ValueKey('button_far'),
                            onPressed: () {},
                            child: const Text('Far'),
                          ),
                        ),
                        const SizedBox(width: 400.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TourRunner runner() => container.read(tourRunnerProvider);
  BuildContext appContext(WidgetTester tester) => tester.element(find.byType(Scaffold));
  final overlay = find.byKey(const ValueKey('tour_overlay'));

  Future<void> start(WidgetTester tester, {bool force = false}) async {
    await runner().run(appContext(tester), tour, force: force);
    await tester.pumpAndSettle();
  }

  Rect spotlight(WidgetTester tester) =>
      (tester.widget<CustomPaint>(find.byKey(const ValueKey('tour_spotlight'))).painter! as SpotlightPainter).hole;

  testWidgets('spotlights the real button and explains it', (tester) async {
    await pumpApp(tester);

    await start(tester);

    expect(find.text('Step A'), findsOneWidget);
    expect(find.text('About A'), findsOneWidget);
    final button = tester.getRect(find.byKey(const ValueKey('button_a'))).inflate(6.0);
    final hole = spotlight(tester);
    expect(hole.left, closeTo(button.left, 0.5));
    expect(hole.top, closeTo(button.top, 0.5));
    expect(hole.right, closeTo(button.right, 0.5));
    expect(hole.bottom, closeTo(button.bottom, 0.5));
  });

  testWidgets('Next walks the steps, skipping targets that are not on screen', (tester) async {
    await pumpApp(tester);
    await start(tester);
    expect(find.text('1 of 3'), findsOneWidget, reason: 'the missing target is left out');

    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();
    expect(find.text('Step B'), findsOneWidget);
    expect(find.text('Step Missing'), findsNothing);
    expect(find.text('2 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();
    expect(find.text('Step Far'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.byKey(const ValueKey('tour_skip')), findsNothing, reason: 'nothing left to skip');

    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    expect(runner().isRunning, isFalse);
  });

  testWidgets('scrolls an off-screen target into view before spotlighting it', (tester) async {
    await pumpApp(tester);
    await start(tester);
    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();

    final far = tester.getRect(find.byKey(const ValueKey('button_far')));
    expect(far.left, greaterThanOrEqualTo(0.0));
    expect(far.right, lessThanOrEqualTo(800.0));
    expect(spotlight(tester).contains(far.center), isTrue);
  });

  testWidgets('the bubble sits below a target near the top and above one near the bottom', (tester) async {
    await pumpApp(tester);
    await start(tester);

    final bubbleTop = tester.getTopLeft(find.byKey(const ValueKey('tour_bubble'))).dy;
    expect(bubbleTop, greaterThan(tester.getBottomLeft(find.byKey(const ValueKey('button_a'))).dy));

    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tour_next')));
    await tester.pumpAndSettle();
    final bubbleBottom = tester.getBottomLeft(find.byKey(const ValueKey('tour_bubble'))).dy;
    expect(bubbleBottom, lessThan(tester.getTopLeft(find.byKey(const ValueKey('button_far'))).dy));
  });

  testWidgets('Skip closes the tour at once', (tester) async {
    await pumpApp(tester);
    await start(tester);

    await tester.tap(find.byKey(const ValueKey('tour_skip')));
    await tester.pumpAndSettle();

    expect(overlay, findsNothing);
    expect(runner().isRunning, isFalse);
  });

  testWidgets('the app underneath cannot be used during the tour', (tester) async {
    await pumpApp(tester);
    await start(tester);

    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('button_a'))));
    await tester.pump();
    expect(taps, 0, reason: 'taps are swallowed by the tour');

    await tester.tap(find.byKey(const ValueKey('tour_skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('button_a')));
    expect(taps, 1);
  });

  testWidgets('a tour is remembered as seen when it starts, and does not repeat', (tester) async {
    await pumpApp(tester);
    expect(repository.seen, isEmpty);

    await start(tester);
    expect(repository.seen, {'demo'});
    await tester.tap(find.byKey(const ValueKey('tour_skip')));
    await tester.pumpAndSettle();

    final startedAgain = await runner().run(appContext(tester), tour);
    await tester.pumpAndSettle();

    expect(startedAgain, isFalse);
    expect(overlay, findsNothing);
  });

  testWidgets('force replays a seen tour (the Help button)', (tester) async {
    await pumpApp(tester, unseen: false);

    expect(await runner().run(appContext(tester), tour), isFalse);
    await start(tester, force: true);

    expect(overlay, findsOneWidget);
  });

  testWidgets('only one tour runs at a time', (tester) async {
    await pumpApp(tester);
    await start(tester);

    final second = await runner().run(appContext(tester), tour, force: true);

    expect(second, isFalse);
    expect(overlay, findsOneWidget);
  });

  testWidgets('a tour whose targets are all missing does not start', (tester) async {
    await pumpApp(tester);

    const orphan = TourDefinition(id: 'orphan', steps: [TourStep(anchorId: 'nowhere', title: 'T', body: 'B')]);
    final started = await runner().run(appContext(tester), orphan);
    await tester.pumpAndSettle();

    expect(started, isFalse);
    expect(overlay, findsNothing);
  });

  testWidgets('an anchor stops being a target once it leaves the screen', (tester) async {
    await pumpApp(tester);
    expect(container.read(tourRegistryProvider).contextFor('a'), isNotNull);

    await tester.pumpWidget(const SizedBox());

    expect(container.read(tourRegistryProvider).contextFor('a'), isNull);
  });

  group('TourHost', () {
    Future<void> pumpHostApp(WidgetTester tester, {required bool unseen}) async {
      repository = unseen ? MemoryTutorialRepository.unseen() : MemoryTutorialRepository();
      container = ProviderContainer(overrides: [tutorialRepositoryProvider.overrideWithValue(repository)]);
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const ValueKey('open_screen'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TourHost(
                          autoStart: TourDefinition(
                            id: 'screen',
                            steps: [TourStep(anchorId: 'screen_button', title: 'Hello', body: 'Tap here')],
                          ),
                          child: Scaffold(
                            body: Center(
                              child: TourAnchor(id: 'screen_button', child: Text('Anchor', key: ValueKey('anchor_text'))),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('starts on the first visit, after the page transition has finished', (tester) async {
      await pumpHostApp(tester, unseen: true);

      await tester.tap(find.byKey(const ValueKey('open_screen')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(overlay, findsNothing, reason: 'the page is still sliding in');

      await tester.pumpAndSettle();
      expect(overlay, findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      final anchor = tester.getRect(find.byKey(const ValueKey('anchor_text'))).inflate(6.0);
      final hole = (tester.widget<CustomPaint>(find.byKey(const ValueKey('tour_spotlight'))).painter! as SpotlightPainter).hole;
      expect(hole.center.dx, closeTo(anchor.center.dx, 0.5), reason: 'measured after the page stopped moving');
      expect(hole.center.dy, closeTo(anchor.center.dy, 0.5));
    });

    testWidgets('does not start again on later visits', (tester) async {
      await pumpHostApp(tester, unseen: false);

      await tester.tap(find.byKey(const ValueKey('open_screen')));
      await tester.pumpAndSettle();

      expect(overlay, findsNothing);
    });

    testWidgets('closes a running tour when the screen goes away', (tester) async {
      await pumpHostApp(tester, unseen: true);
      await tester.tap(find.byKey(const ValueKey('open_screen')));
      await tester.pumpAndSettle();
      expect(overlay, findsOneWidget);

      Navigator.of(tester.element(find.byKey(const ValueKey('anchor_text')))).pop();
      await tester.pumpAndSettle();

      expect(overlay, findsNothing);
      expect(container.read(tourRunnerProvider).isRunning, isFalse);
    });
  });
}
