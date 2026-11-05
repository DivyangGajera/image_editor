# Chitred: The Photo Editor

An offline Android photo editor with tools for promotional graphics: edit photos, design posts, stories and banners, and export them in high resolution. Your projects and everything in them stay on your device.

## Features

- **Projects:** a gallery of your designs with thumbnails. Start from a format preset (Post 1:1, Feed 4:5, Story 9:16, Banner 16:9), a custom size, a photo, or a collage. Rename, duplicate and delete projects.
- **Layered editor:** photos, text, stickers and freehand drawing. Move, pinch, rotate (with a one-finger handle that snaps to right angles), duplicate, reorder and hide layers.
- **Undo/redo:** 500 steps per project, kept across app restarts.
- **Photos:** filters, flip, crop that you can always redo or undo, and offline background removal (ML Kit).
- **Text:** size, bold/italic, colors, shadow and background box, with a live preview.
- **Fonts:**
  - The app ships with one built-in font.
  - You can download from a curated set of Google Fonts (English, Hindi, Gujarati), with live previews and a real internet check.
  - You can import your own .ttf/.otf files, including legacy fonts such as Kruti Dev.
  - Fonts persist across restarts, and you can delete them and download them again.
- **Stickers:** bundled promo badges, plus My stickers, where you import your own PNGs and logos.
- **Collages and filmstrips:** combine 2–9 photos into a layout you can keep editing.
- **Export:** PNG or JPEG at Standard, 2K or 4K, saved to the Gallery's Chitred album. An optional brand watermark (text or logo) is set up once and offered on every export.

## Development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
flutter build apk --release
```

Architecture, conventions and project rules are in [`AGENTS.md`](AGENTS.md) and [`CLAUDE.md`](CLAUDE.md).
