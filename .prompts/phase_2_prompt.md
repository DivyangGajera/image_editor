Implement the core domain entities and serialization logic for our image editing workspace.

1. In lib/features/layers/domain/models/, create the layer schema:
    - abstract class CanvasLayer: fields id (String), x (double, normalized 0.0-1.0), y (double, normalized 0.0-1.0), scale (double), rotation (double, radians), zIndex (int), isVisible (bool).
    - ImageLayer: extends CanvasLayer. Adds relativeImagePath (String), isFlippedHorizontally (bool), activeFilter (String?), cropRect (List?).
    - TextLayer: extends CanvasLayer. Adds text (String), fontFamily (String), isCustomFont (bool), customFontPath (String?), textColorValue (int), fontSize (double), isBold (bool), isItalic (bool), boxColorValue (int?), boxBorderRadius (double), shadowColorValue (int?).
    - DoodleLayer: extends CanvasLayer. Adds points (List<List>), strokeColorValue (int), strokeWidth (double), hasGlow (bool).
    - StickerLayer: extends CanvasLayer. Adds assetPath (String).

2. In lib/features/canvas/domain/models/, create ProjectModel:
    - Fields: id (String), title (String), canvasWidth (double), canvasHeight (double), layers (List), createdAt (DateTime), updatedAt (DateTime).
    - Provide immutable copyWith methods for all models.

3. Add Hive CE TypeAdapters annotations (@HiveType, @HiveField) for all models with explicit unique typeIds.

4. Run dart run build_runner build --delete-conflicting-outputs and write unit tests in test/features/layers/domain/models_test.dart asserting proper serialization/deserialization and copyWith behavior.