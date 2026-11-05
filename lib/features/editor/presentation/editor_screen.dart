import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/widgets/busy_overlay.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/presentation/canvas_view.dart';
import 'package:image_editor/features/editor/application/application.dart';
import 'package:image_editor/features/editor/presentation/widgets/background_color_sheet.dart';
import 'package:image_editor/features/editor/presentation/widgets/editor_bottom_bars.dart';
import 'package:image_editor/features/editor/presentation/widgets/layers_sheet.dart';
import 'package:image_editor/features/export/presentation/screens/export_screen.dart';
import 'package:image_editor/features/history/application/history_notifier.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/doodle_canvas_overlay.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_edit_sheet.dart';
import 'package:image_editor/features/projects/presentation/widgets/project_actions_sheet.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';
import 'package:image_editor/features/segmentation/presentation/background_removal_prompt.dart';
import 'package:image_editor/features/segmentation/presentation/background_remover_download.dart';
import 'package:image_editor/features/segmentation/presentation/widgets/segmentation_progress_bar.dart';
import 'package:image_editor/features/stickers/presentation/widgets/sticker_picker_sheet.dart';
import 'package:image_picker/image_picker.dart';

/// The main editing workspace for one project.
///
/// Top bar: back, undo/redo, layers and export. Center: the canvas. Bottom:
/// add-content tools, or actions for the selected layer, or brush settings
/// while drawing.
class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key, required this.projectId});

  final String projectId;

  /// Route opening the editor for [projectId].
  static Route<void> route(String projectId) {
    return MaterialPageRoute<void>(
      builder: (_) => EditorScreen(projectId: projectId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvas = ref.watch(canvasProvider(projectId));

    return switch (canvas) {
      AsyncData() => _EditorWorkspace(projectId: projectId),
      AsyncError(:final error) => _EditorMessage(
          icon: Icons.error_outline_rounded,
          message: error is StateError
              ? 'This project could not be found.'
              : 'Something went wrong while opening this project.',
        ),
      _ => const _EditorMessage(),
    };
  }
}

/// Loading (no [message]) or error page with a back button.
class _EditorMessage extends StatelessWidget {
  const _EditorMessage({this.icon, this.message});

  final IconData? icon;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: message == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48.0, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16.0),
                    Text(message!, textAlign: TextAlign.center),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EditorWorkspace extends ConsumerWidget {
  const _EditorWorkspace({required this.projectId});

  final String projectId;

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs [action], reporting any failure in a snackbar instead of crashing.
  Future<void> _guard(
    BuildContext context,
    String failureMessage,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
      // Logged so device logs show the real cause behind the friendly message.
      AppLogger.error(failureMessage, tag: 'Editor', error: error, stackTrace: stackTrace);
      if (context.mounted) _showError(context, failureMessage);
    }
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('photo_source_gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              key: const ValueKey('photo_source_camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    await _guard(context, 'Could not add the photo.', () async {
      final commands = ref.read(editorCommandsProvider(projectId));
      final photo = await BusyOverlay.during(
        context,
        message: 'Importing photo…',
        task: (showBusy) => commands.importPhoto(source, onPicked: showBusy),
      );
      if (photo == null || !context.mounted) return;

      final bytes = await commands.readImportedPhoto(photo);
      if (!context.mounted) return;
      final cutout = await BackgroundRemovalPrompt.show(context, imageBytes: bytes);
      await commands.addImportedPhoto(photo, cutoutPng: cutout);
    });
  }

  Future<void> _addText(BuildContext context, WidgetRef ref) async {
    final text = await TextEditSheet.show(context);
    if (text == null || !context.mounted) return;
    await ref.read(editorCommandsProvider(projectId)).addText(text);
  }

  Future<void> _editText(BuildContext context, WidgetRef ref, TextLayer layer) async {
    final edited = await TextEditSheet.show(context, initialLayer: layer);
    if (edited == null || !context.mounted) return;
    await ref.read(canvasProvider(projectId).notifier).updateLayer(edited);
  }

  Future<void> _addSticker(BuildContext context, WidgetRef ref) async {
    final selection = await StickerPickerSheet.show(context);
    if (selection == null || !context.mounted) return;
    await _guard(context, 'Could not add the sticker.', () async {
      await ref.read(editorCommandsProvider(projectId)).addSticker(selection);
    });
  }

  Future<void> _removeBackground(BuildContext context, WidgetRef ref, String layerId) async {
    final commands = ref.read(editorCommandsProvider(projectId));
    final ready = await BackgroundRemoverDownload.ensureReady(
      context,
      ref,
      readyMessage: 'Background remover is ready. Tap Remove BG to remove the background of the selected image.',
    );
    if (!ready || !context.mounted) return;
    try {
      await commands.removeBackground(layerId);
    } on BackgroundRemovalException catch (error) {
      final detail = error.detail;
      if (context.mounted) {
        _showError(context, detail == null ? error.message : '${error.message}\nDetails: $detail');
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'Background removal failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasNotifier = ref.read(canvasProvider(projectId).notifier);
    final uiNotifier = ref.read(editorUiProvider(projectId).notifier);
    final ui = ref.watch(editorUiProvider(projectId));
    final history = ref.watch(historyProvider(projectId));
    final isSegmenting = ref.watch(segmentationProvider.select((s) => s.isProcessing));

    final title = ref.watch(
      canvasProvider(projectId).select((s) => s.requireValue.project.title),
    );
    final selectedLayer = ref.watch(
      canvasProvider(projectId).select((s) => s.requireValue.selectedLayer),
    );
    final isEmpty = ref.watch(
      canvasProvider(projectId).select((s) => s.requireValue.project.layers.isEmpty),
    );

    final quick = EditorQuickActions(
      onUndo: history.canUndo ? canvasNotifier.undo : null,
      onRedo: history.canRedo ? canvasNotifier.redo : null,
      onLayers: () => LayersSheet.show(context, projectId),
    );

    final Widget bottomBar;
    if (ui.mode == EditorMode.draw) {
      bottomBar = DrawToolBar(
        key: const ValueKey('draw_bar'),
        quick: quick,
        colorValue: ui.drawColorValue,
        strokeWidth: ui.drawStrokeWidth,
        minStrokeWidth: EditorUiState.minStrokeWidth,
        maxStrokeWidth: EditorUiState.maxStrokeWidth,
        hasGlow: ui.drawGlow,
        onColorChanged: uiNotifier.setDrawColor,
        onStrokeWidthChanged: uiNotifier.setDrawStrokeWidth,
        onToggleGlow: uiNotifier.toggleDrawGlow,
        onDone: uiNotifier.exitDrawMode,
      );
    } else if (selectedLayer != null) {
      final layer = selectedLayer;
      bottomBar = LayerContextBar(
        key: ValueKey('context_bar_${layer.runtimeType}'),
        quick: quick,
        layer: layer,
        isFilterStripOpen: ui.isFilterStripOpen,
        isBusy: isSegmenting,
        onDeselect: () {
          uiNotifier.closeFilterStrip();
          canvasNotifier.selectLayer(null);
        },
        onDuplicate: () => canvasNotifier.duplicateLayer(layer.id),
        onToggleLock: () => canvasNotifier.toggleLock(layer.id),
        onBringToFront: () => canvasNotifier.bringToFront(layer.id),
        onSendToBack: () => canvasNotifier.sendToBack(layer.id),
        onDelete: () {
          uiNotifier.closeFilterStrip();
          canvasNotifier.deleteLayer(layer.id);
        },
        onToggleFilters: uiNotifier.toggleFilterStrip,
        onFilterSelected: (filterId) {
          if (layer is ImageLayer) {
            canvasNotifier.updateLayer(
              layer.copyWith(activeFilter: filterId, clearActiveFilter: filterId == null),
            );
          }
        },
        onFlip: () {
          if (layer is ImageLayer) {
            canvasNotifier.updateLayer(
              layer.copyWith(isFlippedHorizontally: !layer.isFlippedHorizontally),
            );
          }
        },
        onRemoveBackground: () => _removeBackground(context, ref, layer.id),
        onEditText: () {
          if (layer is TextLayer) _editText(context, ref, layer);
        },
        onCrop: () => _guard(context, 'Could not crop the photo.', () async {
          await ref.read(editorCommandsProvider(projectId)).cropImage(layer.id);
        }),
        onResetCrop: () =>
            ref.read(editorCommandsProvider(projectId)).resetCrop(layer.id),
      );
    } else {
      bottomBar = MainToolBar(
        key: const ValueKey('main_bar'),
        quick: quick,
        onAddPhoto: () => _addPhoto(context, ref),
        onAddText: () => _addText(context, ref),
        onAddSticker: () => _addSticker(context, ref),
        onDraw: () {
          canvasNotifier.selectLayer(null);
          uiNotifier.enterDrawMode();
        },
        onBackground: () async {
          final current = canvasNotifier.currentState.project.backgroundColorValue;
          final color = await BackgroundColorSheet.show(context, initialColor: current);
          if (color != null) await canvasNotifier.setBackgroundColor(color);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.canvasBackdrop,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        title: Tooltip(
          message: 'Rename project',
          child: InkWell(
            key: const ValueKey('editor_title'),
            borderRadius: BorderRadius.circular(8.0),
            onTap: () async {
              final newTitle = await showRenameProjectDialog(context, title);
              if (newTitle != null) await canvasNotifier.renameProject(newTitle);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(Icons.edit_outlined, size: 16.0),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 12.0),
            child: FilledButton(
              key: const ValueKey('editor_export'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(84.0, 40.0),
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                canvasNotifier.selectLayer(null);
                ExportScreen.show(
                  context,
                  ref.read(canvasProvider(projectId)).requireValue.project,
                );
              },
              child: const Text('Export'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CanvasView(
                      projectId: projectId,
                      overlayBuilder: ui.mode == EditorMode.draw
                          ? (canvasSize) => DoodleCanvasOverlay(
                                key: const ValueKey('doodle_overlay'),
                                canvasSize: canvasSize,
                                strokeColor: Color(ui.drawColorValue),
                                strokeWidth: ui.drawStrokeWidth,
                                hasGlow: ui.drawGlow,
                                onDoodleFinished: (doodle) =>
                                    canvasNotifier.addLayer(doodle, select: false),
                              )
                          : null,
                    ),
                  ),
                ),
                if (isEmpty && ui.mode != EditorMode.draw) const Center(child: _EmptyCanvasHint()),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SegmentationProgressBar(message: 'Removing background…'),
                ),
              ],
            ),
          ),
        ],
      ),
      // As the bottom navigation bar, snackbars appear above the tools
      // instead of covering them.
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: bottomBar,
      ),
    );
  }
}

/// Shown over an empty canvas: where to start.
class _EmptyCanvasHint extends StatelessWidget {
  const _EmptyCanvasHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return IgnorePointer(
      child: Container(
        key: const ValueKey('empty_canvas_hint'),
        margin: const EdgeInsets.symmetric(horizontal: 48.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 26.0,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.add_photo_alternate_outlined, color: colors.primary),
            ),
            const SizedBox(height: 12.0),
            Text('Start with a photo or some text', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4.0),
            Text(
              'Use the tools below. Scroll them sideways for more.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
