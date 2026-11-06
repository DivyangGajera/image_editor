import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/tutorial/application/tour_registry.dart';

/// Marks [child] as a target a tour can spotlight, under [id]. It adds no
/// widget or layout of its own: the spotlight covers [child]'s own box.
class TourAnchor extends ConsumerStatefulWidget {
  const TourAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  ConsumerState<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends ConsumerState<TourAnchor> {
  // Resolved once: dispose() must not use ref.
  late final TourRegistry _registry;

  @override
  void initState() {
    super.initState();
    _registry = ref.read(tourRegistryProvider);
    _registry.register(widget.id, context);
  }

  @override
  void didUpdateWidget(TourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _registry.unregister(oldWidget.id, context);
      _registry.register(widget.id, context);
    }
  }

  @override
  void dispose() {
    _registry.unregister(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
