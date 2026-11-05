import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/layers/application/layer_placement.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';
import 'package:image_editor/features/stickers/data/user_sticker_repository.dart';
import 'package:image_editor/features/stickers/domain/models/sticker_selection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
    required this._userStickers,
    AssetSizeReader? readAssetSize,
  }) : _readAssetSize = readAssetSize ?? readBundledImageSize;

  final String projectId;
  final CanvasNotifier Function() _canvas;
  final CanvasState Function() _canvasState;
  final ImageImportService _imageImport;
  final SegmentationNotifier Function() _segmentation;
  final ProjectRepository _projectRepository;
  final UserStickerRepository _userStickers;
  final AssetSizeReader _readAssetSize;

  ui.Size get _canvasSize {
    final project = _canvasState().project;
    return ui.Size(project.canvasWidth, project.canvasHeight);
  }

  /// Lets the user pick and crop a photo from [source] and saves it into the
  /// project. Returns null if the user cancelled. Add it with
  /// [addImportedPhoto] (after optionally removing its background).
  Future<ImportedPhoto?> importPhoto(ImageSource source) {
    return _imageImport.importPhoto(source: source, projectId: projectId);
  }

  /// Bytes of an imported photo, e.g. for the background-removal prompt.
  Future<Uint8List> readImportedPhoto(ImportedPhoto photo) async =>
      (await _projectRepository.resolveRelativePath(photo.relativePath)).readAsBytes();

  /// Adds [photo] to the canvas, fitted to the canvas. With [cutoutPng] the
  /// cut-out is saved and used instead; it then crops on its own, so it gets
  /// no separate original.
  Future<void> addImportedPhoto(ImportedPhoto photo, {Uint8List? cutoutPng}) async {
    final String imagePath;
    final String? originalPath;
    if (cutoutPng != null) {
      imagePath = await _projectRepository.saveLayerImage(
        projectId,
        cutoutPng,
        'cutout_${const Uuid().v4()}.png',
      );
      originalPath = null;
    } else {
      imagePath = photo.relativePath;
      originalPath = photo.originalPath;
    }

    await _canvas().addLayer(
      ImageLayer(
        id: const Uuid().v4(),
        x: 0.5,
        y: 0.5,
        scale: LayerPlacement.fitScale(contentSize: photo.size, canvasSize: _canvasSize),
        relativeImagePath: imagePath,
        originalImagePath: originalPath,
      ),
    );
  }

  /// Adds a new text layer, scaled so its font size reads like it would on a
  /// phone-width canvas (see [LayerPlacement.textScale]).
  Future<void> addText(TextLayer text) async {
    await _canvas().addLayer(
      text.copyWith(scale: LayerPlacement.textScale(_canvasSize.width)),
    );
  }

  /// Adds the chosen sticker sized to [LayerPlacement.stickerWidthFraction]
  /// of the canvas width. User stickers are copied into the project first, so
  /// the design keeps working even if the sticker is removed from My stickers.
  Future<void> addSticker(StickerSelection selection) async {
    final StickerLayer layer;
    final double contentWidth;
    switch (selection) {
      case BundledStickerSelection(:final item):
        contentWidth = (await _readAssetSize(item.assetPath)).width;
        layer = StickerLayer(id: const Uuid().v4(), x: 0.5, y: 0.5, assetPath: item.assetPath);
      case UserStickerSelection(:final sticker):
        final bytes = await (await _userStickers.resolve(sticker.relativePath)).readAsBytes();
        final projectPath = await _projectRepository.saveLayerImage(
          projectId,
          bytes,
          'sticker_${const Uuid().v4()}${p.extension(sticker.relativePath)}',
        );
        contentWidth = sticker.width.toDouble();
        layer = StickerLayer(
          id: const Uuid().v4(),
          x: 0.5,
          y: 0.5,
          assetPath: sticker.relativePath,
          relativeFilePath: projectPath,
        );
    }

    final scale = LayerPlacement.widthScale(
      contentWidth: contentWidth,
      canvasWidth: _canvasSize.width,
    );
    await _canvas().addLayer(layer.copyWith(scale: scale));
  }

  /// Runs offline background removal on the image layer [layerId] and places
  /// the cutout over it. Returns false if the layer is not an image.
  Future<bool> removeBackground(String layerId) async {
    final layer = _findImage(layerId);
    if (layer == null) return false;

    final source = await _projectRepository.resolveRelativePath(layer.relativeImagePath);
    final cutout = await _segmentation().extractBackground(
      sourceImagePath: source.path,
      projectId: projectId,
    );
    if (cutout == null) return false;

    await _canvas().applyCutout(layerId, cutout);
    return true;
  }

  /// Re-crops image layer [layerId] starting from its uncropped original, so
  /// earlier crops can be widened again. Position, scale, rotation, flip and
  /// filter are kept. Returns false if cancelled or the layer is not an image.
  Future<bool> cropImage(String layerId) async {
    final layer = _findImage(layerId);
    if (layer == null) return false;

    // Images without a recorded original (cutouts, collage cells) start
    // cropping from their current file, which then becomes the original.
    final original = layer.originalImagePath ?? layer.relativeImagePath;
    final cropped = await _imageImport.recrop(projectId: projectId, originalPath: original);
    if (cropped == null) return false;

    await _canvas().updateLayer(
      layer.copyWith(relativeImagePath: cropped.relativePath, originalImagePath: original),
    );
    return true;
  }

  /// Restores the uncropped original of image layer [layerId] (undoable).
  Future<void> resetCrop(String layerId) async {
    final layer = _findImage(layerId);
    if (layer == null || !layer.isCropped) return;
    await _canvas().updateLayer(layer.copyWith(relativeImagePath: layer.originalImagePath));
  }

  ImageLayer? _findImage(String layerId) {
    final layer = _canvasState().project.layers.where((l) => l.id == layerId).firstOrNull;
    return layer is ImageLayer ? layer : null;
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
///
/// Widgets read this provider without listening, so it is disposed right
/// after the read while a command may still be waiting for the photo picker,
/// cropper or an asset. The commands therefore hold the notifier *instances*
/// (resolved here, up front) and never use this provider's `ref` later.
@riverpod
EditorCommands editorCommands(Ref ref, String projectId) {
  final canvas = ref.read(canvasProvider(projectId).notifier);
  final segmentation = ref.read(segmentationProvider.notifier);
  return EditorCommands(
    projectId: projectId,
    canvas: () => canvas,
    canvasState: () => canvas.currentState,
    imageImport: ref.watch(imageImportServiceProvider),
    segmentation: () => segmentation,
    projectRepository: ref.watch(projectRepositoryProvider),
    userStickers: ref.watch(userStickerRepositoryProvider),
  );
}
