# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The project's engineering rules live in `AGENTS.md` (identical copy at `.agents/rules/project_rules.md`) and are mandatory. Key points: feature-first layering with no empty layer folders, heavy pixel work off the UI thread, project-relative paths only, never add a pubspec dependency without explicit user approval, ask before implementing ambiguous requirements, tests with every change, and a Conventional Commit after each verified change.

@AGENTS.md

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing @riverpod / @HiveType code
flutter analyze --fatal-infos                               # CI uses --fatal-infos, so infos fail the build too
flutter test                                                # full suite
flutter test test/features/canvas/application/canvas_notifier_test.dart          # single file
flutter test test/features/history/history_manager_test.dart --plain-name "undo" # single test by name
flutter build apk --release
```

CI (`.github/workflows/flutter_ci.yml`) runs pub get → build_runner → analyze `--fatal-infos` → test `--coverage` → release APK on push/PR to `master`/`main`. Generated `*.g.dart` files (including `lib/hive_registrar.g.dart`) are committed and excluded from analysis.

## Git workflow
Work on short-lived branches off `master` (`feat/*`, `fix/*`, `refactor/*`, `chore/*`, `docs/*`), make small Conventional Commits, and merge back with `git merge --no-ff`. Gate every commit on the real results of `flutter analyze --fatal-infos` and the tests: a `| grep`/`| tail` pipeline does not fail. `git rm` stages deletions immediately, so check what is staged before committing. Do not push unless the user asks.

## App overview
Chitred ("Chitred: The Photo Editor") is an offline Android photo editor with promotional-graphics tools: Riverpod 3 with codegen, Hive CE, light Material 3 theme (`core/theme/app_theme.dart`).

`main()` runs `AppBootstrap.initialize()` (Hive in `<docs>/hive/`, all adapters via the generated registrar), pre-loads the font library, reads the first-run flag (`OnboardingRepository`, settings box) to show `WelcomeScreen` once, then starts on `HomeScreen` (project gallery) → `EditorScreen(projectId)` → `ExportScreen`.

Each feature in `lib/features/<feature>/` has a barrel (`<feature>.dart`), and so does each layer folder.

## State management (Riverpod 3 + riverpod_generator 4)
- Every provider uses `@riverpod` / `@Riverpod(keepAlive: true)`. Generated names drop the `Notifier` suffix: `CanvasNotifier` → `canvasProvider`, `HistoryNotifier` → `historyProvider`, `ProjectsNotifier` → `projectsProvider`, `FontLibraryNotifier` → `fontLibraryProvider`.
- Services are keep-alive singletons. Per-project state (`canvasProvider(projectId)`, `historyProvider(projectId)`, `editorUiProvider(projectId)`) is auto-disposed when the editor closes.
- **Never touch `ref` after an `await`** without checking `ref.mounted`. Providers can be disposed mid-operation (for example, the editor closing during a disk write). Resolve dependencies first (in `build()` or before the await) and publish state only while mounted. Regression tests cover this for the canvas, history, projects and font library.

## Core editing data flow
- `ProjectModel` (Hive typeId 4) holds the canvas size and a `List<CanvasLayer>`. List index == `zIndex`, from bottom to top.
- `CanvasLayer` subclasses: `ImageLayer`=0, `TextLayer`=1, `DoodleLayer`=2, `StickerLayer`=3. Type IDs are registered in `HiveTypeIds` (`core/storage/storage_keys.dart`): also `FontEntry`=5 and `UserSticker`=6. Never reuse a type ID or a retired `@HiveField` index (`ImageLayer` field 10 is retired). Shared `CanvasLayer` fields are 0–6 plus `isLocked` at 30 (subclass fields use 7–29); a locked layer can be selected but `TransformableBox` and `previewTransform` never move it.
- Providers that widgets only `read` are disposed right after the read. Anything holding a provider's `ref` across an `await` must instead capture the notifier instances up front (see `editorCommandsProvider`). This caused the "could not add photo/sticker" bug.
- Layer `x`/`y` are **normalized** (0–1, layer center). `copyWith` on the base class is polymorphic over the base fields.
- `CanvasNotifier` (AsyncNotifier keyed by project ID) loads the project from `ProjectRepository`. Mutations go through `_commit`: state is updated synchronously, then the previous layers are pushed to history and the project is saved. Dependencies are captured before awaiting, so edits survive disposal.
- Gestures follow begin → preview → commit: `beginInteraction` snapshots the layers, `previewTransform` updates state only (no history, no disk), and `commitInteraction` records one undo step. `TransformableBox` converts screen deltas using the canvas view scale (`CanvasCoordinateConverter`).
- `HistoryManager` is a persistent 500-step undo/redo engine. Each undo step is a `CanvasSnapshot` (Hive typeId 7: layers plus the background color), written through to a Hive `LazyBox<dynamic>` (`history_<projectId>`, with a `meta` key); only the newest 50 are cached in RAM. Legacy frames (plain layer lists) still load, as white. It survives restarts, and all operations run through a serial queue.
- `ProjectModel.backgroundColorValue` (HiveField 7, default white) is the solid canvas background, set with the editor's Background tool (`CanvasNotifier.setBackgroundColor`, undoable).
- Images are normalized on import (`ImageNormalizer`, in an isolate: EXIF baked, ≤2048 px, JPEG unless transparent). HEIC/HEIF/AVIF (and anything else the `image` package can't sniff) is first converted to JPEG by `PlatformImageConverter` through the engine codec, which falls back to Android's ImageDecoder (Android 9+); collage cells go through it too. The uncropped original is kept (`originalImagePath`) so Crop/Uncrop can be redone.
- Doodle points are relative to the stroke's bounding box (`DoodleGeometry`).

## Persistence rules
- Persist only relative paths. Project files go in `projects/<id>/images/` and the thumbnail in `projects/<id>/thumbnail.png`. App-wide files: `fonts/`, `stickers/`, `branding/`.
- User stickers are **copied into the project** when placed, so projects are self-contained. `ProjectRepository.duplicateProject` remaps image, original and sticker paths.

## Fonts (`features/fonts`)
- Only the built-in default (`systemDefaultFontFamily` = `Roboto`) ships with the app.
- A curated catalog of 55 Google Fonts families (English, Hindi, Gujarati) downloads on demand from the keyless CSS API (`GoogleFontsClient`, `dart:io` behind `HttpGetter`). Previews are ~2 KB subsets (`fontPreviewFamilyProvider`).
- Connectivity is a real request (`isReachable`), not connectivity_plus.
- Imports (`FontFilePicker`) accept any file, validated by signature, and are registered as `user:<file name>`. This includes legacy glyph fonts.
- `FontResolver` applies a family only if it is installed. Otherwise text falls back to the default font, and the editor shows a missing-font badge.

## Export (`features/export`)
- `CanvasExportService.renderAtSize` draws everything in canvas units under one scale transform (`ExportResolution`: Standard / 2K / 4K, preserving the canvas aspect ratio). Text uses `TextLayerStyle` + `FontResolver`, exactly like the canvas.
- `ExportNotifier` saves through `GallerySaver` (gal) into the "Chitred" album.
- The brand watermark (`WatermarkSettingsNotifier`) is configured once. `isEnabled` is never persisted: the main **Export** button exports without the watermark, and **Export with watermark** is the alternative.
- `ExportScreen` (full screen) pins a live preview at the top: `CanvasExportService.renderPreview` renders the design once without a watermark, and `WatermarkPreviewPainter` paints the watermark over it with `WatermarkRenderer`, the same code the export uses, so the preview matches the saved file. Below are format, quality and the watermark settings (text or logo, size incl. `logoScale`, position, opacity), saved automatically after a short pause.
- Slow imports after a system picker report `onPicked`, and `BusyOverlay.during` shows a blocking "Importing…" overlay from then until they finish.

## Background removal (`features/segmentation`)
- ML Kit **Subject Segmentation** (people, pets, products, cars), not Selfie Segmentation. The model is delivered by Google Play services; the manifest's `com.google.mlkit.vision.DEPENDENCIES=subject_segment` requests it at install time.
- The model is requested at app start (`SubjectModelInstaller.ensureModel`, via `MainActivity`'s `chitred/ml_models` channel). Before removal, `BackgroundRemoverDownload.ensureReady` checks `isAvailable()`; if missing, it offers the download ("Not now" does nothing), shows byte progress from the `chitred/ml_models/download` event channel (`ModelDownloadNotifier`, internet checked first with `InternetCheck`), then a snackbar asks the user to tap Remove BG again. Editor and prompt bottom bars are `bottomNavigationBar`s so snackbars don't cover them.
- `BackgroundRemovalService.cutOut(bytes)` returns a transparent PNG. `SubjectMasker` is the seam for tests. `BackgroundRemovalException` carries user-facing messages (no subject; model not ready).
- Every image import (editor photo, new project from photo, My stickers, watermark logo) is followed by `BackgroundRemovalPrompt`, which returns the cut-out bytes or null to keep the original. Cut-out photos have no `originalImagePath`.

## Heavy processing (always off the UI isolate)
Background removal (`PixelCutoutProcessor`), collage cells (`CollageEngine`), image/sticker/logo normalization, and JPEG encoding all run in `Isolate.run`. Pass only plain data across the isolate boundary.

## Testing notes
- Widget tests run in a fake-async zone, but Hive and file I/O complete in real time. Do real I/O in `setUp` or inside `tester.runAsync`, and start gestures that lead to I/O inside `runAsync`.
- Wait for outcomes with `test/helpers/pump_until.dart` instead of fixed sleeps, which are flaky when the full suite runs in parallel.
- `test/helpers/fixed_font_library.dart` fakes installed fonts.
- Register Hive adapters only through `AppBootstrap.registerAdapters` (the generated registrar). Reference Hive default values with their class name, because the generator copies them into the adapter unqualified.

## Android
`minSdk` 24. `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 29) and `requestLegacyExternalStorage` are required by gal for gallery saving on Android 9/10. Release builds are shrunk by R8: `android/app/proguard-rules.pro` keeps ML Kit and Play services classes, which they look up by name at runtime (without it, background removal crashes with null-reference errors in release only). Native libraries must stay 16 KB page-aligned: check with `zipalign -c -P 16` and the ELF LOAD alignment.
