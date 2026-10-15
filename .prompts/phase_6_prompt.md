Build the Canvas rendering UI widget in lib/features/canvas/presentation/canvas_view.dart.

1. Use a fixed-aspect-ratio container inside a responsive viewport (AspectRatio inside FittedBox or InteractiveViewer).

2. Inside, use a Stack that renders layers ordered by zIndex.

3. Create an interactive wrapper TransformableBox:
 - Listens to touch/drag gestures using GestureDetector.
 - When a layer is tapped, set it as selectedLayerId.
 - When selected, draw an overlay bounding box with 4 corner anchors (scale/rotate handles) and a delete button.
 - Two-finger pan, pinch-to-scale, and twist-to-rotate should update normalized coordinates on CanvasNotifier.

4. Prevent UI jank: ensure only the active layer widget rebuilds during drag gestures by isolating sub-notifiers or using selective .select() listeners.