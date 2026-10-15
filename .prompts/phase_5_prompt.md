Implement the core interactive Canvas Controller using Riverpod.
1. Create CanvasNotifier in lib/features/canvas/application/canvas_notifier.dart:
 - State holds: ProjectModel, String? selectedLayerId, bool isInteracting
 - Implement methods:
   - addLayer(CanvasLayer layer)
   - updateLayerTransform(String id, {double? x, double? y, double? scale, double? rotation})
   - reorderLayer(int oldIndex, int newIndex) (swaps zIndex and stack order) 
   - bringToFront(String id), sendToBack(String id)
   - deleteLayer(String id)
   - selectLayer(String? id)
 - Connect every mutating method to automatically record the state in HistoryNotifier.
2. Write coordinate transformation helpers:
 - Convert screen viewport touch offsets (pixels) into normalized $(0.0 - 1.0)$ coordinates based on canvas aspect ratio
3. Write unit tests verifying layer re-indexing and state emissions.