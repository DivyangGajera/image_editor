import 'package:flutter/material.dart';
import 'package:image_editor/features/tutorial/application/tour_registry.dart';
import 'package:image_editor/features/tutorial/domain/tour.dart';

/// Dims the screen, cuts a spotlight around the current step's target and
/// explains it in a bubble with Next / Skip. Blocks taps on the app below.
class TourOverlay extends StatefulWidget {
  const TourOverlay({super.key, required this.steps, required this.registry, required this.onClose});

  final List<TourStep> steps;
  final TourRegistry registry;

  /// Called when the tour is finished or skipped.
  final VoidCallback onClose;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  static const Duration scrollDuration = Duration(milliseconds: 250);
  static const double spotlightPadding = 6.0;

  int _index = 0;
  Rect? _target;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  /// Scrolls the current target into view, then measures it.
  Future<void> _prepare() async {
    final index = _index;
    final context = widget.registry.contextFor(widget.steps[index].anchorId);
    if (context == null) {
      _advance();
      return;
    }
    try {
      await Scrollable.ensureVisible(context, alignment: 0.5, duration: scrollDuration, curve: Curves.easeOut);
    } on Object {
      // Not scrollable, or already detached: measure where it is.
    }
    if (!mounted || index != _index) return;

    final box = context.mounted ? context.findRenderObject() : null;
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      _advance();
      return;
    }
    setState(() => _target = box.localToGlobal(Offset.zero) & box.size);
  }

  void _advance() {
    if (_index >= widget.steps.length - 1) {
      widget.onClose();
      return;
    }
    setState(() => _index++);
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;
    final target = _target;

    Widget? bubble;
    if (target != null) {
      final hole = target.inflate(spotlightPadding);
      final above = hole.center.dy > size.height / 2;
      bubble = Positioned(
        left: 16.0,
        right: 16.0,
        top: above ? null : hole.bottom + 12.0,
        bottom: above ? size.height - hole.top + 12.0 : null,
        child: DecoratedBox(
          key: const ValueKey('tour_bubble'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24.0, offset: Offset(0, 8))],
          ),
          // Material gives the texts and buttons their default styles.
          child: Material(
            color: colors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 12.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, key: const ValueKey('tour_title'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6.0),
                  Text(step.body, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text(
                        '${_index + 1} of ${widget.steps.length}',
                        key: const ValueKey('tour_progress'),
                        style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          key: const ValueKey('tour_skip'),
                          onPressed: widget.onClose,
                          child: const Text('Skip'),
                        ),
                      FilledButton(
                        key: const ValueKey('tour_next'),
                        style: FilledButton.styleFrom(minimumSize: const Size(88.0, 40.0)),
                        onPressed: _advance,
                        child: Text(isLast ? 'Got it' : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      key: const ValueKey('tour_overlay'),
      children: [
        // Swallows taps, so the app below cannot be used mid-tour.
        const ModalBarrier(dismissible: false, color: Colors.transparent),
        if (target != null)
          IgnorePointer(
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(end: target.inflate(spotlightPadding)),
              duration: scrollDuration,
              curve: Curves.easeOut,
              builder: (context, rect, _) => CustomPaint(
                key: const ValueKey('tour_spotlight'),
                size: Size.infinite,
                painter: SpotlightPainter(hole: rect ?? target, ringColor: colors.tertiary),
              ),
            ),
          )
        else
          const IgnorePointer(
            child: ColoredBox(color: Color(0xB8000000), child: SizedBox.expand()),
          ),
        ?bubble,
      ],
    );
  }
}

/// Paints a dimmed screen with a rounded hole around [hole] and a ring on
/// its edge.
class SpotlightPainter extends CustomPainter {
  const SpotlightPainter({required this.hole, required this.ringColor});

  final Rect hole;
  final Color ringColor;

  static const double radius = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(hole, const Radius.circular(radius));
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rounded);
    canvas.drawPath(dim, Paint()..color = const Color(0xB8000000));
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) => oldDelegate.hole != hole || oldDelegate.ringColor != ringColor;
}
