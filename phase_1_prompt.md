Initialize a clean, production-ready Flutter app targeting Android and

1. Update pubspec.yaml with the following production dependencies:
    - flutter_riverpod, riverpod_annotation
    - hive_ce, hive_ce_flutter
    - image (pure Dart image library)
    - google_mlkit_selfie_segmentation
    - image_cropper, image_picker
    - path_provider, path, uuid
    - google_fonts

2. Add dev dependencies: build_runner, riverpod_generator, hive_ce_generator, flutter_lints, mocktail.

3. Configure Android native build:
    - Set minSdkVersion 21 (required for ML Kit) in android/app/build.gradle.
    - Set permissions in AndroidManifest.xml for reading/writing external media and camera.

4. Establish the folder structure:
```
lib/
  ├── core/
  │   ├── constants/
  │   ├── storage/
  │   └── utils/
  └── features/
      ├── canvas/
      ├── layers/
      ├── history/
      ├── segmentation/
      ├── collage/
      └── export/
```

5. Create a minimal main.dart wrapped in ProviderScope and verify that flutter analyze passes."