import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';

/// A sleek, non-blocking progress bar widget displayed when background extraction
/// is running in the background isolate.
class SegmentationProgressBar extends ConsumerWidget {
  const SegmentationProgressBar({
    super.key,
    this.message = 'Extracting background...',
  });

  /// Status text displayed next to the progress bar.
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(segmentationProvider);

    if (!state.isProcessing) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('segmentation_progress_bar'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (state.progress != null)
                Text(
                  '${(state.progress! * 100).toInt()}%',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 4.0,
            ),
          ),
        ],
      ),
    );
  }
}
