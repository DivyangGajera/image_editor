import 'package:flutter/material.dart';

/// Icon-over-label button used in the editor's bottom bars.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Highlights the button (e.g. an open panel).
  final bool isActive;

  /// Uses the error color (e.g. delete).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final Color foreground;
    if (!enabled) {
      foreground = colors.onSurface.withValues(alpha: 0.38);
    } else if (isDestructive) {
      foreground = colors.error;
    } else if (isActive) {
      foreground = colors.primary;
    } else {
      foreground = colors.onSurfaceVariant;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 58.0, minHeight: 56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isActive ? colors.primaryContainer : null,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Icon(icon, size: 22.0, color: foreground),
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
