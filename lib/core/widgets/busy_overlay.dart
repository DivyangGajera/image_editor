import 'package:flutter/material.dart';

/// A blocking "working…" overlay for slow steps that follow a system picker,
/// such as converting a large HEIC photo, so the app never looks frozen.
abstract final class BusyOverlay {
  /// Runs [task] and shows [message] over the whole app from the moment the
  /// task calls the `showBusy` callback it receives (e.g. once the user has
  /// picked a file) until the task finishes, fails or is cancelled.
  ///
  /// Showing it only on that signal keeps it out of the way while a system
  /// picker is open.
  static Future<T> during<T>(
    BuildContext context, {
    required String message,
    required Future<T> Function(VoidCallback showBusy) task,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    OverlayEntry? entry;
    void show() {
      if (entry != null || !overlay.mounted) return;
      entry = OverlayEntry(builder: (_) => BusyIndicator(message: message));
      overlay.insert(entry!);
    }

    try {
      return await task(show);
    } finally {
      entry?.remove();
      entry?.dispose();
    }
  }
}

/// Dimmed, input-blocking backdrop with a progress card.
class BusyIndicator extends StatelessWidget {
  const BusyIndicator({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('busy_overlay'),
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black38),
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(dimension: 28.0, child: CircularProgressIndicator()),
                  const SizedBox(width: 20.0),
                  Text(message, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
