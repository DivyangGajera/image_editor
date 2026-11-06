import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/features/tutorial/tutorial.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tutorial_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('a tour is unseen until marked, and tours are remembered separately', () async {
    final repository = TutorialRepository();
    expect(await repository.hasSeen('editor'), isFalse);

    await repository.markSeen('editor');

    expect(await repository.hasSeen('editor'), isTrue);
    expect(await repository.hasSeen('export'), isFalse);
  });

  test('seen tours stay seen after a restart', () async {
    await TutorialRepository().markSeen('export');
    await Hive.close();
    Hive.init(tempDir.path);

    expect(await TutorialRepository().hasSeen('export'), isTrue);
  });

  test('every tour has a stable id, steps, and only known anchors', () {
    final ids = [Tours.editor, Tours.photoTools, Tours.textTools, Tours.export].map((t) => t.id);
    expect(ids.toSet().length, 4, reason: 'ids are unique');

    for (final tour in [Tours.editor, Tours.photoTools, Tours.textTools, Tours.export]) {
      expect(tour.steps, isNotEmpty, reason: tour.id);
      for (final step in tour.steps) {
        expect(step.title, isNotEmpty);
        expect(step.body, isNotEmpty);
      }
    }
  });
}
