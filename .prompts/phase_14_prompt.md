Harden the application with end-to-end unit tests, integration tests, and CI configuration.

1. In test/:
 - Unit test HistoryNotifier: verify 500-step rollback and redo behavior under rapid event firing.
 - Unit test ProjectRepository: test sandboxing, file deletion, and relative path resolution.
 - Widget test CanvasView: verify layer tap selection, transformation handle rendering, and gesture input without throwing render overflow exceptions.

2. Create a GitHub Actions workflow in .github/workflows/flutter_ci.yml:
 - Steps:
   1. Checkout code.
   2. Setup Flutter (latest stable).
   3. Run flutter pub get.
   4. Run dart run build_runner build --delete-conflicting-outputs.
   5. Run flutter analyze --fatal-infos.
   6. Run flutter test --coverage.
   7. Build Android APK: flutter build apk --release.

3. Run all tests now and fix any failing tests or linter warnings across the entire repository."