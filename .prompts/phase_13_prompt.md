Implement the final export engine to render the canvas workspace into a production-grade image file.
1. Create CanvasExportService in lib/features/export/canvas_export_service.dart:
 - Use ui.PictureRecorder and Flutter's headless Canvas API (NOT RepaintBoundary, which is tied to device screen resolution).
 - Draw all layers according to their z-index, normalized transforms, filters, texts, stickers, and vector paths at arbitrary export resolutions (e.g., $1080 \times 1080$ or $1080 \times 1920$).
2. Watermark Implementation:
 - Support adding a watermark layer: configurable text or transparent PNG logo.
 - Positioning options: Bottom-Right, Bottom-Left, Center, or Tiled across the image with configurable opacity.
3. Convert the recorded picture to ui.Image, encode to PNG/JPEG bytes (toByteData(format: ui.ImageByteFormat.png)).
4. Save to gallery via native storage channel and display a share sheet modal.