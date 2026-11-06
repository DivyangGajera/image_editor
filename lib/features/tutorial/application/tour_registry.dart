import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tour_registry.g.dart';

/// Where the tour finds its targets: widgets register themselves under an id
/// (see `TourAnchor`) while they are on screen.
class TourRegistry {
  final Map<String, BuildContext> _anchors = <String, BuildContext>{};

  void register(String id, BuildContext context) => _anchors[id] = context;

  /// Removes [context]'s registration. A newer widget that registered under
  /// the same id in the meantime (e.g. during a transition) is kept.
  void unregister(String id, BuildContext context) {
    if (identical(_anchors[id], context)) _anchors.remove(id);
  }

  /// The target registered under [id], or null if it is not on screen.
  BuildContext? contextFor(String id) {
    final context = _anchors[id];
    return context != null && context.mounted ? context : null;
  }
}

/// App-wide [TourRegistry].
@Riverpod(keepAlive: true)
TourRegistry tourRegistry(Ref ref) => TourRegistry();
