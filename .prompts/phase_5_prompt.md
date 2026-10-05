Implement our memory-efficient 500-step Undo/Redo Engine.
1. In `lib/features/history/data/history_manager.dart`:
   - Maximum depth: 500 actions. In-memory RAM limit: 50 actions.
   - Data structure: Maintain two in-memory stacks: `_undoStack` and `_redoStack` (holding `List<CanvasLayer>`).
   - Disk Spillover: When `_undoStack.length > 50`, pop the oldest snapshot and write it to a dedicated Hive box `history_<projectId>` using an indexed ring key (`0..499`).
   - Pre-fetching: When user invokes `undo()` and `_undoStack.length < 5`, trigger an asynchronous background read to load the preceding 50 frames from the Hive box into the bottom of `_undoStack`.
   - Redo purge: Pushing a new state invalidates `_redoStack` and discards forward branch history.
2. Expose methods:
   - `pushState(List<CanvasLayer> layers)`
   - `Future<List<CanvasLayer>?> undo(List<CanvasLayer> currentLayers)`
   - `Future<List<CanvasLayer>?> redo(List<CanvasLayer> currentLayers)`
   - `bool get canUndo`, `bool get canRedo`.
3. Create a Riverpod `HistoryNotifier` managing this lifecycle.
4. Write rigorous unit tests in `test/features/history/history_manager_test.dart` verifying memory boundary conditions (pushing 60 actions, verifying memory stays $\le 50$, and verifying undo triggers disk recovery).