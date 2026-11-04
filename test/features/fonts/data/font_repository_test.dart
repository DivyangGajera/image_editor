import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/fonts/data/font_repository.dart';
import 'package:image_editor/features/fonts/domain/font_entry.dart';
import 'package:image_editor/features/fonts/domain/font_file_validator.dart';

void main() {
  late Directory tempDir;
  late FontRepository repository;

  setUpAll(AppBootstrap.registerAdapters);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('font_repository_test_');
    Hive.init(tempDir.path);
    repository = FontRepository(
      getBaseDir: () async => tempDir,
      fontsBox: await Hive.openBox<FontEntry>(StorageKeys.fontsBox),
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

  test('save writes the file under fonts/ and stores only a relative path', () async {
    final entry = await repository.save(
      family: 'Poppins',
      displayName: 'Poppins',
      isImported: false,
      bytes: bytes,
      format: FontFileFormat.trueType,
      now: DateTime(2026, 11, 5),
    );

    expect(entry.relativePath, 'fonts/${entry.id}.ttf');
    expect(entry.sizeBytes, 64);
    expect(await repository.readBytes(entry), bytes);
    expect((await repository.getAll()).single, entry);
  });

  test('entries survive closing and reopening storage', () async {
    final entry = await repository.save(
      family: 'user:Kruti Dev 010',
      displayName: 'Kruti Dev 010',
      isImported: true,
      bytes: bytes,
      format: FontFileFormat.openType,
    );
    await Hive.close();

    Hive.init(tempDir.path);
    final reopened = FontRepository(
      getBaseDir: () async => tempDir,
      fontsBox: await Hive.openBox<FontEntry>(StorageKeys.fontsBox),
    );

    expect((await reopened.getAll()).single, entry);
    expect(entry.relativePath, endsWith('.otf'));
  });

  test('getAll sorts by display name, case-insensitively', () async {
    for (final name in ['mukta', 'Anton', 'Lobster']) {
      await repository.save(
        family: name,
        displayName: name,
        isImported: false,
        bytes: bytes,
        format: FontFileFormat.trueType,
      );
    }

    expect((await repository.getAll()).map((e) => e.displayName), ['Anton', 'Lobster', 'mukta']);
  });

  test('delete removes the record and the file', () async {
    final entry = await repository.save(
      family: 'Anton',
      displayName: 'Anton',
      isImported: false,
      bytes: bytes,
      format: FontFileFormat.trueType,
    );

    await repository.delete(entry);

    expect(await repository.getAll(), isEmpty);
    expect((await repository.resolve(entry.relativePath)).existsSync(), isFalse);
  });
}
