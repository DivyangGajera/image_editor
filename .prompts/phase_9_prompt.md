Implement the Sticker & Promo Badge system for ad creatives.

1. Create directory assets/stickers/ with categorized subfolders:
 - discounts/ (e.g., '50% OFF', 'BUY 1 GET 1')
 - urgency/ (e.g., 'LIMITED TIME', 'SALE ENDS TODAY')
 - badges/ (e.g., 'BESTSELLER', 'NEW ARRIVAL')

2. Create StickerRepository providing a categorized manifest of bundled stickers.

3. Build StickerPickerBottomSheet:
 - Tabbed UI by category.
 - Grid of thumbnails.
 -  Tapping a sticker instantiates a StickerLayer placed centered on the canvas with normalized dimensions, registering it into the layer stack.