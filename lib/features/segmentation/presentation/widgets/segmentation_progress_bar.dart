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
    final state = ref.watch(segmentationNotifierProvider);

    if (!state.isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('segmentation_progress_bar'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(240),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF4E95FF).withAlpha(100),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E95FF)),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (state.progress != null)
                Text(
                  '${(state.progress! * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF4E95FF),
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
              backgroundColor: const Color(0xFF2E2E40),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4E95FF)),
            ),
          ),
        ],
      ),
    );
  }
}
