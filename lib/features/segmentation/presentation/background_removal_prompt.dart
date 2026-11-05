import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';

/// Asks, right after an image is imported, whether to remove its background.
///
/// Shows the image with "Keep original" and "Remove background". After
/// removal the user can compare and choose "Use cut-out" or keep the
/// original. [show] returns the cut-out PNG bytes, or null for the original
/// (also when the user simply goes back, so an import is never lost).
class BackgroundRemovalPrompt extends ConsumerStatefulWidget {
  const BackgroundRemovalPrompt({super.key, required this.imageBytes, required this.title});

  final Uint8List imageBytes;
  final String title;

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    String title = 'Remove background?',
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BackgroundRemovalPrompt(imageBytes: imageBytes, title: title),
      ),
    );
  }

  @override
  ConsumerState<BackgroundRemovalPrompt> createState() => _BackgroundRemovalPromptState();
}

class _BackgroundRemovalPromptState extends ConsumerState<BackgroundRemovalPrompt> {
  Uint8List? _cutout;
  bool _showCutout = false;
  bool _busy = false;
  String? _error;

  Future<void> _removeBackground() async {
    final service = ref.read(backgroundRemovalServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cutout = await service.cutOut(widget.imageBytes);
      if (!mounted) return;
      setState(() {
        _cutout = cutout;
        _showCutout = true;
      });
    } on BackgroundRemovalException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Background removal failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cutout = _cutout;
    final shown = _showCutout && cutout != null ? cutout : widget.imageBytes;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Keep original',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CustomPaint(painter: CheckerboardPainter()),
                      Image.memory(
                        shown,
                        key: ValueKey(_showCutout ? 'prompt_cutout' : 'prompt_original'),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                      if (_busy)
                        ColoredBox(
                          color: colors.surface.withValues(alpha: 0.7),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16.0),
                                Text('Removing background…'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (cutout != null)
              SegmentedButton<bool>(
                key: const ValueKey('prompt_compare'),
                segments: const [
                  ButtonSegment(value: false, label: Text('Original')),
                  ButtonSegment(value: true, label: Text('Cut-out')),
                ],
                selected: {_showCutout},
                onSelectionChanged: (s) => setState(() => _showCutout = s.first),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 0.0),
                child: Text(
                  _error!,
                  key: const ValueKey('prompt_error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('prompt_keep_original'),
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Keep original'),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: cutout == null
                        ? FilledButton.icon(
                            key: const ValueKey('prompt_remove_background'),
                            onPressed: _busy ? null : _removeBackground,
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: const Text('Remove background'),
                          )
                        : FilledButton(
                            key: const ValueKey('prompt_use_cutout'),
                            onPressed: () => Navigator.of(context).pop(cutout),
                            child: const Text('Use cut-out'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light grey checkerboard that reveals transparent areas of an image.
class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter();

  static const double cell = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    final dark = Paint()..color = const Color(0xFFE5E7EB);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        if (((x / cell).floor() + (y / cell).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CheckerboardPainter oldDelegate) => false;
}
