import 'package:flutter/foundation.dart';

/// One stop of a tour: spotlights the widget registered under [anchorId]
/// and explains it.
@immutable
class TourStep {
  const TourStep({required this.anchorId, required this.title, required this.body});

  final String anchorId;
  final String title;
  final String body;
}

/// A short guided walk through real buttons. [id] is what is remembered as
/// "seen", so it must stay stable.
@immutable
class TourDefinition {
  const TourDefinition({required this.id, required this.steps});

  final String id;
  final List<TourStep> steps;
}

/// Ids the screens register their tour targets under (see `TourAnchor`).
abstract final class TourAnchors {
  static const String toolPhoto = 'editor.photo';
  static const String toolText = 'editor.text';
  static const String toolSticker = 'editor.sticker';
  static const String toolBackground = 'editor.background';
  static const String quickActions = 'editor.quick_actions';
  static const String exportButton = 'editor.export';
  static const String removeBackground = 'editor.remove_bg';
  static const String crop = 'editor.crop';
  static const String editText = 'editor.edit_text';
  static const String lock = 'editor.lock';

  static const String exportPreview = 'export.preview';
  static const String watermarkType = 'export.watermark_type';
  static const String watermarkPosition = 'export.watermark_position';
  static const String watermarkOpacity = 'export.watermark_opacity';
  static const String exportActions = 'export.actions';
}

/// Every tour of the app.
abstract final class Tours {
  /// The first time a design opens, and from the editor's Help button.
  static const TourDefinition editor = TourDefinition(
    id: 'editor',
    steps: [
      TourStep(
        anchorId: TourAnchors.toolPhoto,
        title: 'Add a photo',
        body:
            'Tap Photo to pick one from your gallery or take a new one. '
            'You can remove its background right after.',
      ),
      TourStep(
        anchorId: TourAnchors.toolText,
        title: 'Add text',
        body:
            'Type your offer in English, Hindi or Gujarati. '
            'Choose Font in the text window to download more fonts.',
      ),
      TourStep(
        anchorId: TourAnchors.toolSticker,
        title: 'Stickers and your logo',
        body: 'Add offer badges and stickers. Open My stickers and tap Import to use your own logo or PNG.',
      ),
      TourStep(
        anchorId: TourAnchors.toolBackground,
        title: 'Background colour',
        body: 'Change the colour behind your design.',
      ),
      TourStep(
        anchorId: TourAnchors.quickActions,
        title: 'Undo, Redo and Layers',
        body: 'Made a mistake? Undo it. Layers lets you reorder, hide or lock each item.',
      ),
      TourStep(
        anchorId: TourAnchors.exportButton,
        title: 'Export',
        body: 'When you are done, tap Export. You can add your brand watermark there.',
      ),
    ],
  );

  /// The first time a photo is selected.
  static const TourDefinition photoTools = TourDefinition(
    id: 'photo_tools',
    steps: [
      TourStep(
        anchorId: TourAnchors.removeBackground,
        title: 'Remove the background',
        body:
            'Cut out your product or person in one tap. It works on your phone, '
            'with no internet after the first download.',
      ),
      TourStep(
        anchorId: TourAnchors.crop,
        title: 'Crop',
        body: 'Trim your photo to the part you want. You can bring the rest back with Uncrop.',
      ),
      TourStep(
        anchorId: TourAnchors.lock,
        title: 'Lock',
        body: 'Lock the photo so it cannot be moved by accident while you work on other things.',
      ),
    ],
  );

  /// The first time a text layer is selected.
  static const TourDefinition textTools = TourDefinition(
    id: 'text_tools',
    steps: [
      TourStep(
        anchorId: TourAnchors.editText,
        title: 'Edit your text',
        body:
            'Change the words, font, colour, size, shadow and background box. '
            'You can also drag the text around the design.',
      ),
      TourStep(anchorId: TourAnchors.lock, title: 'Lock', body: 'Lock the text so it stays exactly where you put it.'),
    ],
  );

  /// The first time Export opens, and from its Help button.
  static const TourDefinition export = TourDefinition(
    id: 'export',
    steps: [
      TourStep(
        anchorId: TourAnchors.exportPreview,
        title: 'Live preview',
        body: 'This is exactly how your image will look, with your watermark on it.',
      ),
      TourStep(
        anchorId: TourAnchors.watermarkType,
        title: 'Your watermark',
        body: 'Use your shop name as text, or your logo. It is remembered for next time.',
      ),
      TourStep(
        anchorId: TourAnchors.watermarkPosition,
        title: 'Where it goes',
        body: 'Pick a corner or the centre, or repeat it across the whole image.',
      ),
      TourStep(
        anchorId: TourAnchors.watermarkOpacity,
        title: 'Size and strength',
        body: 'Adjust the size and opacity so it does not hide your design.',
      ),
      TourStep(
        anchorId: TourAnchors.exportActions,
        title: 'Export',
        body:
            'Export saves your image without a watermark. Export with watermark adds yours. '
            'Both go to your Gallery.',
      ),
    ],
  );
}
