import 'dart:ui' as ui;

import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/layers/application/layer_placement.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_commands.g.dart';

/// Reads the pixel size of a bundled image asset.
typedef AssetSizeReader = Future<ui.Size> Function(String assetPath);

/// Editor actions that combine services with canvas mutations, so widgets only
/// trigger intents and never orchestrate I/O themselves.
class EditorCommands {
  EditorCommands({
    required this.projectId,
    required this._canvas,
    required this._canvasState,
    required this._imageImport,
    required this._segmentation,
    required this._projectRepository,
    AssetSizeReader? readAssetSize,
  }) : _readAssetSize = readAssetSize ?? readBundledImageSize;

  final String projectId;
  final CanvasNotifier Function() _canvas;
  final CanvasState Function() _canvasState;
  final ImageImportService _imageImport;
  final SegmentationNotifier Function() _segmentation;
  final ProjectRepository _projectRepository;
  final AssetSizeReader _readAssetSize;

  ui.Size get _canvasSize {
    final project = _canvasState().project;
    return ui.Size(project.canvasWidth, project.canvasHeight);
  }

  /// Lets the user pick and crop a photo from [source] and adds it to the
  /// canvas, fitted to the canvas. Returns false if the user cancelled.
  Future<bool> addPhoto(ImageSource source) async {
    final layer = await _imageImport.pickAndCropImage(
      source: source,
      projectId: projectId,
      canvasSize: _canvasSize,
    );
    if (layer == null) return false;
    await _canvas().addLayer(layer);
    return true;
  }

  /// Adds a sticker sized to [LayerPlacement.stickerWidthFraction] of the
  /// canvas width.
  Future<void> addSticker(StickerLayer sticker) async {
    final assetSize = await _readAssetSize(sticker.assetPath);
    final scale = LayerPlacement.widthScale(
      contentWidth: assetSize.width,
      canvasWidth: _canvasSize.width,
    );
    await _canvas().addLayer(sticker.copyWith(scale: scale));
  }

  /// Runs offline background removal on the image layer [layerId] and places
  /// the cutout over it. Returns false if the layer is not an image.
  Future<bool> removeBackground(String layerId) async {
    final layer = _canvasState().project.layers.where((l) => l.id == layerId).firstOrNull;
    if (layer is! ImageLayer) return false;

    final source = await _projectRepository.resolveRelativePath(layer.relativeImagePath);
    final cutout = await _segmentation().extractBackground(
      sourceImagePath: source.path,
      projectId: projectId,
    );
    if (cutout == null) return false;

    await _canvas().applyCutout(layerId, cutout);
    return true;
  }

  /// Default [AssetSizeReader]: reads only the image header of a bundled asset.
  static Future<ui.Size> readBundledImageSize(String assetPath) async {
    final buffer = await ui.ImmutableBuffer.fromAsset(assetPath);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = ui.Size(descriptor.width.toDouble(), descriptor.height.toDouble());
      descriptor.dispose();
      return size;
    } finally {
      buffer.dispose();
    }
  }
}

/// [EditorCommands] bound to the canvas of [projectId].
@riverpod
EditorCommands editorCommands(Ref ref, String projectId) {
  return EditorCommands(
    projectId: projectId,
    canvas: () => ref.read(canvasProvider(projectId).notifier),
    canvasState: () => ref.read(canvasProvider(projectId)).requireValue,
    imageImport: ref.watch(imageImportServiceProvider),
    segmentation: () => ref.read(segmentationProvider.notifier),
    projectRepository: ref.watch(projectRepositoryProvider),
  );
}
