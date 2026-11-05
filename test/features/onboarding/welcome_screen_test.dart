import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/onboarding/onboarding.dart';

/// Welcome state held in memory.
class MemoryOnboarding extends OnboardingRepository {
  bool seen = false;

  @override
  Future<bool> hasSeenWelcome() async => seen;

  @override
  Future<void> markWelcomeSeen() async => seen = true;
}

void main() {
  group('OnboardingRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('onboarding_test_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('the welcome is unseen until marked, and stays seen after a restart', () async {
      expect(await OnboardingRepository().hasSeenWelcome(), isFalse);

      await OnboardingRepository().markWelcomeSeen();
      await Hive.close();
      Hive.init(tempDir.path);

      expect(await OnboardingRepository().hasSeenWelcome(), isTrue);
    });
  });

  group('WelcomeScreen', () {
    late MemoryOnboarding onboarding;
    late int done;

    Future<void> pumpWelcome(WidgetTester tester) async {
      onboarding = MemoryOnboarding();
      done = 0;
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [onboardingRepositoryProvider.overrideWithValue(onboarding)],
          child: MaterialApp(theme: AppTheme.light(), home: WelcomeScreen(onDone: () => done++)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Next walks through the pages and Get started finishes', (tester) async {
      await pumpWelcome(tester);

      expect(find.text(WelcomeScreen.pages[0].title), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome_next')));
      await tester.pumpAndSettle();
      expect(find.text(WelcomeScreen.pages[1].title), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome_next')));
      await tester.pumpAndSettle();
      expect(find.text(WelcomeScreen.pages[2].title), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_skip')), findsNothing, reason: 'nothing left to skip');

      await tester.tap(find.byKey(const ValueKey('welcome_next')));
      await tester.pumpAndSettle();

      expect(onboarding.seen, isTrue);
      expect(done, 1);
    });

    testWidgets('Skip remembers the welcome and finishes at once', (tester) async {
      await pumpWelcome(tester);

      await tester.tap(find.byKey(const ValueKey('welcome_skip')));
      await tester.pumpAndSettle();

      expect(onboarding.seen, isTrue);
      expect(done, 1);
    });

    testWidgets('pages can also be swiped', (tester) async {
      await pumpWelcome(tester);

      await tester.drag(find.byKey(const ValueKey('welcome_pages')), const Offset(-250, 0));
      await tester.pumpAndSettle();

      expect(find.text(WelcomeScreen.pages[1].title), findsOneWidget);
    });
  });
}
