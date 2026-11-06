import 'package:image_editor/features/tutorial/tutorial.dart';

/// [TutorialRepository] held in memory. By default every tour counts as
/// already seen, so screens under test do not start one; use
/// [MemoryTutorialRepository.unseen] to test the first-time behaviour.
class MemoryTutorialRepository extends TutorialRepository {
  MemoryTutorialRepository() : allSeen = true;

  MemoryTutorialRepository.unseen() : allSeen = false;

  final bool allSeen;
  final Set<String> seen = <String>{};

  @override
  Future<bool> hasSeen(String tourId) async => allSeen || seen.contains(tourId);

  @override
  Future<void> markSeen(String tourId) async => seen.add(tourId);
}
