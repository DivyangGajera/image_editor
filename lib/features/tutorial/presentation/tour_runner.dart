import 'package:flutter/widgets.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/tutorial/application/tour_registry.dart';
import 'package:image_editor/features/tutorial/data/tutorial_repository.dart';
import 'package:image_editor/features/tutorial/domain/tour.dart';
import 'package:image_editor/features/tutorial/presentation/tour_overlay.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tour_runner.g.dart';

/// Starts tours: shows the spotlight overlay above the whole app and
/// remembers which tours were shown. One tour runs at a time.
class TourRunner {
  TourRunner({required this.registry, required this.repository});

  final TourRegistry registry;
  final TutorialRepository repository;

  OverlayEntry? _entry;

  bool get isRunning => _entry != null;

  /// Shows [tour] unless it was seen before (or [force], e.g. from a Help
  /// button) or another tour is running. Steps whose target is not on screen
  /// are skipped. Returns whether a tour started. A tour counts as seen as
  /// soon as it starts, so an interrupted tour is not nagged again.
  Future<bool> run(BuildContext context, TourDefinition tour, {bool force = false}) async {
    if (_entry != null) return false;
    if (!force) {
      try {
        if (await repository.hasSeen(tour.id)) return false;
      } on Object catch (error, stackTrace) {
        AppLogger.error('Tour state could not be read', tag: 'Tutorial', error: error, stackTrace: stackTrace);
        return false;
      }
    }
    if (_entry != null || !context.mounted) return false;

    final steps = [
      for (final step in tour.steps)
        if (registry.contextFor(step.anchorId) != null) step,
    ];
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (steps.isEmpty || overlay == null) return false;

    final entry = OverlayEntry(
      builder: (_) => TourOverlay(steps: steps, registry: registry, onClose: dismiss),
    );
    _entry = entry;
    overlay.insert(entry);

    try {
      await repository.markSeen(tour.id);
    } on Object catch (error, stackTrace) {
      AppLogger.error('Tour state could not be saved', tag: 'Tutorial', error: error, stackTrace: stackTrace);
    }
    return true;
  }

  /// Closes the running tour, if any.
  void dismiss() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    entry.dispose();
  }
}

/// App-wide [TourRunner].
@Riverpod(keepAlive: true)
TourRunner tourRunner(Ref ref) =>
    TourRunner(registry: ref.watch(tourRegistryProvider), repository: ref.watch(tutorialRepositoryProvider));
