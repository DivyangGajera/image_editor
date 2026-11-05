import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/segmentation/application/model_download_notifier.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';

/// Makes sure the background remover is installed before it is used.
abstract final class BackgroundRemoverDownload {
  /// Returns true when the background remover can run now.
  ///
  /// Otherwise asks whether to download it. "Not now" closes the dialog and
  /// does nothing. "Download" shows a progress dialog; when it finishes,
  /// [readyMessage] is shown in a snackbar so the user can tap Remove
  /// background again. Returns false in both cases.
  static Future<bool> ensureReady(
    BuildContext context,
    WidgetRef ref, {
    required String readyMessage,
  }) async {
    final installer = ref.read(subjectModelInstallerProvider);
    if (await installer.isAvailable()) return true;
    if (!context.mounted) return false;

    final download = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('bg_model_offer'),
        icon: const Icon(Icons.download_rounded),
        title: const Text('Download background remover?'),
        content: const Text(
          'Removing backgrounds needs a small one-time download from Google Play services. '
          'Turn on mobile data or Wi-Fi, then tap Download.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('bg_model_not_now'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const ValueKey('bg_model_download'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (download != true || !context.mounted) return false;

    final installed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ModelDownloadDialog(),
    );
    if (installed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('bg_model_ready'),
          content: Text(readyMessage),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return false;
  }
}

/// Shows the model download with its size and progress. Pops true once the
/// model is installed, false when cancelled.
class ModelDownloadDialog extends ConsumerStatefulWidget {
  const ModelDownloadDialog({super.key});

  @override
  ConsumerState<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends ConsumerState<ModelDownloadDialog> {
  @override
  void initState() {
    super.initState();
    // Start after the first frame: providers must not change during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(modelDownloadProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(modelDownloadProvider, (_, next) {
      if (next is ModelDownloadCompleted) Navigator.of(context).pop(true);
    });
    final state = ref.watch(modelDownloadProvider);
    final theme = Theme.of(context);

    final Widget content = switch (state) {
      ModelDownloadChecking() => const _Busy(text: 'Checking your internet connection…'),
      ModelDownloadCompleted() => const _Busy(text: 'Finishing…'),
      ModelDownloadInProgress(:final progress) => _Progress(progress: progress),
      ModelDownloadOffline() => const Text(
          'No internet connection. Turn on mobile data or Wi-Fi and tap Retry.',
          key: ValueKey('bg_model_offline'),
        ),
      ModelDownloadFailed(:final detail) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The download did not finish. Check your connection and tap Retry.',
              key: const ValueKey('bg_model_failed'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8.0),
            SelectableText(
              'Details: $detail',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
    };
    final canRetry = state is ModelDownloadOffline || state is ModelDownloadFailed;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('bg_model_download_dialog'),
        title: const Text('Background remover'),
        content: content,
        actions: [
          TextButton(
            key: const ValueKey('bg_model_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(canRetry ? 'Cancel' : 'Hide'),
          ),
          if (canRetry)
            FilledButton(
              key: const ValueKey('bg_model_retry'),
              onPressed: () => ref.read(modelDownloadProvider.notifier).start(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox.square(dimension: 28.0, child: CircularProgressIndicator()),
        const SizedBox(width: 16.0),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress});
  final ModelDownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final current = progress;
    final fraction = current?.fraction;
    if (current == null || fraction == null) {
      return const _Busy(text: 'Downloading…');
    }
    return Column(
      key: const ValueKey('bg_model_progress'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Downloading… ${(fraction * 100).round()}%'),
        const SizedBox(height: 12.0),
        LinearProgressIndicator(value: fraction),
        const SizedBox(height: 8.0),
        Text(
          '${formatBytes(current.downloadedBytes)} of ${formatBytes(current.totalBytes)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Human-readable size, e.g. `850 KB` or `4.2 MB`.
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
