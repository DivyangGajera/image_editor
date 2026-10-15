Implement fully offline background extraction using Google ML Kit.
1. Create BackgroundRemovalService in lib/features/segmentation/background_removal_service.dart:
 - Input: source image path on disk.
 - Run ML Kit's SelfieSegmenter (SegmenterMode.singleImage).
 - Obtain the confidence mask buffer (Float32List or byte mask).
2. Concurrency Isolation:
 - Process raw pixel alpha-blending in a dedicated Dart Isolate (via Isolate.run):Read the original image into Dart image package Image bitmap.
  - Apply the mask: set alpha channel to 0 for pixels where mask confidence $< 0.7$.
  - Smooth edges using an erosion or slight box-blur algorithm to remove fringe artifacts.
  - Encode the result as a PNG Uint8List.
3. Save the resulting cutout into the project's sandbox directory and add it as a new ImageLayer.
4. Display a non-blocking linear progress bar or shimmer indicator during processing.