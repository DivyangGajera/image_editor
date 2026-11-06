import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/tutorial/domain/tour.dart';
import 'package:image_editor/features/tutorial/presentation/tour_runner.dart';

/// Wraps a screen so its tour starts the first time it opens ([autoStart]),
/// once its page transition has finished and its targets are on screen, and
/// so a running tour is closed when the screen goes away.
class TourHost extends ConsumerStatefulWidget {
  const TourHost({super.key, this.autoStart, required this.child});

  final TourDefinition? autoStart;
  final Widget child;

  @override
  ConsumerState<TourHost> createState() => _TourHostState();
}

class _TourHostState extends ConsumerState<TourHost> {
  // Resolved once: dispose() must not use ref.
  late final TourRunner _runner;

  @override
  void initState() {
    super.initState();
    _runner = ref.read(tourRunnerProvider);
    if (widget.autoStart != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
    }
  }

  Future<void> _autoStart() async {
    if (!mounted) return;
    await _pageTransitionDone();
    if (!mounted) return;
    await _runner.run(context, widget.autoStart!);
  }

  /// Completes when the screen's push animation has ended, so targets are
  /// measured where they will stay. Uses the animation's status instead of a
  /// timer.
  Future<void> _pageTransitionDone() {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return Future<void>.value();

    final done = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animation.removeStatusListener(onStatus);
        if (!done.isCompleted) done.complete();
      }
    }

    animation.addStatusListener(onStatus);
    return done.future;
  }

  @override
  void dispose() {
    _runner.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
