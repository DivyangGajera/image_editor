import 'package:flutter/material.dart';

/// First-run state of the gallery: an illustration, a short explanation and
/// one clear call to action.
class EmptyProjectsView extends StatelessWidget {
  const EmptyProjectsView({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _EmptyIllustration(),
            const SizedBox(height: 28.0),
            Text(
              'No projects yet',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Edit a photo, design a post or put together a collage. '
              'Everything stays on your device.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28.0),
            FilledButton.icon(
              key: const ValueKey('create_first_project'),
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create your first project'),
            ),
          ],
        ),
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
            width: 84.0,
            height: 104.0,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(color: Color(0x1F000000), blurRadius: 12.0, offset: Offset(0, 4)),
              ],
            ),
            child: Icon(icon, size: 36.0, color: foreground),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Container(
        width: 200.0,
        height: 168.0,
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(32.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            card(Icons.sell_outlined, colors.tertiaryContainer, colors.onTertiaryContainer,
                0.22, const Offset(46, 6)),
            card(Icons.title_rounded, colors.secondaryContainer, colors.onSecondaryContainer,
                -0.22, const Offset(-46, 6)),
            card(Icons.image_outlined, colors.surfaceContainerLowest, colors.primary, 0.0,
                const Offset(0, -4)),
          ],
        ),
      ),
    );
  }
}
