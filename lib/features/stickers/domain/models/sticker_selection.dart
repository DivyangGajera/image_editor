import 'package:image_editor/features/stickers/domain/models/sticker_item.dart';
import 'package:image_editor/features/stickers/domain/models/user_sticker.dart';

/// A sticker chosen in the sticker picker.
sealed class StickerSelection {
  const StickerSelection();
}

/// One of the stickers bundled with the app.
class BundledStickerSelection extends StickerSelection {
  const BundledStickerSelection(this.item);
  final StickerItem item;
}

/// One of the user's own stickers from "My stickers".
class UserStickerSelection extends StickerSelection {
  const UserStickerSelection(this.sticker);
  final UserSticker sticker;
}
