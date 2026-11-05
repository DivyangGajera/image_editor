import 'package:flutter/material.dart';

/// Shown under "Recent designs" before the first project exists.
class EmptyProjectsView extends StatelessWidget {
  const EmptyProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey('empty_projects'),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: [
          const _EmptyIllustration(),
          const SizedBox(height: 20.0),
          Text('No designs yet', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6.0),
          Text(
            'Pick a size above to start. Everything stays on your phone and works without internet.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Three fanned "cards" (photo, text, sticker) hinting at what the app does.
class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget card(IconData icon, Color background, Color foreground, double angle, Offset offset) {
      return Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 64.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14.0),
              boxShadow: const [
                BoxShadow(color: Color(0x1F000000), blurRadius: 10.0, offset: Offset(0, 4)),
              ],
            ),
            child: Icon(icon, size: 28.0, color: foreground),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: 180.0,
        height: 100.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            card(Icons.sell_outlined, colors.tertiary, colors.onTertiary, 0.22, const Offset(44, 4)),
            card(Icons.title_rounded, colors.secondary, colors.onSecondary, -0.22, const Offset(-44, 4)),
            card(Icons.image_outlined, colors.surfaceContainerLowest, colors.primary, 0.0, const Offset(0, -2)),
          ],
        ),
      ),
    );
  }
}
