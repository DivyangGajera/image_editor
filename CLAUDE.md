# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The project's engineering rules live in `AGENTS.md` (identical copy at `.agents/rules/project_rules.md`) and are mandatory. Key points: feature-first layering with no empty layer folders, heavy pixel work off the UI thread, project-relative paths only, never add a pubspec dependency without explicit user approval, ask before implementing ambiguous requirements, tests with every change, and a Conventional Commit after each verified change.

@AGENTS.md

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing @HiveType/@HiveField models
flutter analyze --fatal-infos                               # CI uses --fatal-infos, so infos fail the build too
flutter test                                                # full suite
flutter test test/features/canvas/application/canvas_notifier_test.dart          # single file
flutter test test/features/history/history_manager_test.dart --plain-name "undo" # single test by name
flutter test --coverage
flutter build apk --release
```

CI (`.github/workflows/flutter_ci.yml`) runs these steps in order on push/PR to `master`/`main`: pub get → build_runner → analyze `--fatal-infos` → test `--coverage` → release APK build. Generated `*.g.dart` files are committed and excluded from analysis.

## Architecture

Offline Android image editor (Flutter, Riverpod, Hive CE). `lib/main.dart` currently shows a placeholder home screen whose only entry point is `CollageSetupScreen`; the canvas editor is built and tested but not yet routed from `main`.

Each feature under `lib/features/<feature>/` has a barrel file (`<feature>.dart`), and each layer has its own barrel (`application/application.dart` and so on). Import through the barrels. `features/export/canvas_export_service.dart` and `features/segmentation/background_removal_service.dart` are re-export shims that exist only so the paths named in the original phase prompts work.

### Riverpod: hand-written providers, not codegen
AGENTS.md calls for `@riverpod` code generation, but the code doesn't use it yet. Every provider is declared by hand at the bottom of its file (`Provider<T>`, `NotifierProvider`, `NotifierProvider.family`), and `build_runner` currently generates only Hive adapters. Follow the existing hand-written style unless the user asks for a migration.

### Core editing data flow
- **`ProjectModel`** (`features/canvas/domain`, Hive typeId 4) holds canvas size plus a `List<CanvasLayer>`.
- **`CanvasLayer`** (`features/layers/domain`) is an abstract immutable base with **normalized** `x`/`y` (0–1, layer center relative to the canvas), plus `scale`, `rotation` (radians), `zIndex` and `isVisible`. Its concrete subclasses use these Hive typeIds: `ImageLayer`=0, `TextLayer`=1, `DoodleLayer`=2, `StickerLayer`=3. New Hive types must use the next unused typeId.
- **`CanvasNotifier`** is a `NotifierProvider.family` keyed by the `ProjectModel`. Every mutation follows this sequence: (1) push the current layers to `historyNotifierProvider(project.id)`, (2) compute new layers and assign zIndex, (3) set state, (4) persist with `ProjectRepository.saveProject`. Widgets watch it with granular `.select()` so that only the affected layer rebuilds.
- **`CanvasCoordinateConverter`** converts between normalized layer coordinates and screen/canvas pixels. Use it rather than doing the math inline.
- **History** (`features/history`): `HistoryManager` keeps up to 500 undo snapshots. The newest 50 stay in RAM, and older ones spill into a per-project Hive box `history_<projectId>`. It prefetches from disk when RAM depth falls below 5. The limits are in `core/constants/app_constants.dart`. `HistoryNotifier` is a family keyed by project id.
- **Persistence**: `ProjectRepository` gives each project its own folder at `<appDocs>/projects/<projectId>/images/…`. It returns and stores **only** relative paths (`projects/<id>/images/<file>`) and resolves absolute paths at runtime. Box and directory names are in `core/storage/storage_keys.dart`. Repositories take injectable `getBaseDir`/box parameters so tests can use temp directories.

### Heavy processing (always in isolates)
- **Segmentation**: `BackgroundRemovalService` runs ML Kit selfie segmentation. `PixelCutoutProcessor` applies the mask in `Isolate.run`, using `CutoutProcessingParams` to pass plain data across the isolate boundary. `SegmentationNotifier` tracks progress.
- **Collage**: `CollageEngine` processes cells and frames in `Isolate.run` (`FramedCellParams`). `CollageNotifier` and `CollageConfig` handle layout and filmstrip settings.
- **Export**: `CanvasExportService` renders headlessly with `ui.PictureRecorder` and `ui.Canvas`, independent of the widget tree, then encodes JPEG in an isolate (with an optional watermark from `WatermarkConfig`). `ExportNotifier` drives the dialog.
- Data passed to isolates must be plain, sendable values (bytes, numbers, simple param classes), not Flutter objects.

### Other modules
- `images`: `ImageImportService` (image_picker + image_cropper with custom 4:5 and 9:16 presets), filter bar and editing toolbar. The color-matrix filters are in `core/utils/color_filters.dart`.
- `stickers`: `StickerRepository` loads bundled assets from `assets/stickers/{discounts,urgency,badges}/`. These directories must also be registered in `pubspec.yaml`.
- `layers`: `FontService` (google_fonts), plus the text edit sheet and doodle overlay/painter.

### Android
`minSdk` is 24 (ML Kit needs at least 21). The root Gradle config forces `compileSdk` 36 on plugin subprojects so AARs stay compatible. Native libraries must meet Play Store's 16 KB page-size alignment requirement.

## Tests
Tests mirror `lib/`: `test/features/<feature>/{application,data,domain,presentation}/`. Mocks use `mocktail`. Hive-backed tests open boxes in temp directories through the injectable constructor parameters.
