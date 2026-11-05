import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_repository.g.dart';

/// Remembers whether the first-run welcome was shown, in the settings box.
class OnboardingRepository {
  OnboardingRepository({this.settingsBox});

  static const String welcomeSeenKey = 'welcome_seen';

  Box<dynamic>? settingsBox;

  Future<Box<dynamic>> _box() async {
    final open = settingsBox;
    if (open != null && open.isOpen) return open;
    final box = Hive.isBoxOpen(StorageKeys.settingsBox)
        ? Hive.box<dynamic>(StorageKeys.settingsBox)
        : await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    settingsBox = box;
    return box;
  }

  Future<bool> hasSeenWelcome() async => (await _box()).get(welcomeSeenKey) == true;

  Future<void> markWelcomeSeen() async => (await _box()).put(welcomeSeenKey, true);
}

/// App-wide [OnboardingRepository]; overridden in tests.
@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) => OnboardingRepository();
