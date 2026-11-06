import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tutorial_repository.g.dart';

/// Remembers which tours were already shown, in the settings box.
class TutorialRepository {
  TutorialRepository({this.settingsBox});

  Box<dynamic>? settingsBox;

  static String keyFor(String tourId) => 'tour_seen_$tourId';

  Future<Box<dynamic>> _box() async {
    final open = settingsBox;
    if (open != null && open.isOpen) return open;
    final box = Hive.isBoxOpen(StorageKeys.settingsBox)
        ? Hive.box<dynamic>(StorageKeys.settingsBox)
        : await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    settingsBox = box;
    return box;
  }

  Future<bool> hasSeen(String tourId) async => (await _box()).get(keyFor(tourId)) == true;

  Future<void> markSeen(String tourId) async => (await _box()).put(keyFor(tourId), true);
}

/// App-wide [TutorialRepository]; overridden in tests.
@Riverpod(keepAlive: true)
TutorialRepository tutorialRepository(Ref ref) => TutorialRepository();
