# Flutter Agent Guidelines & Engineering Rules

## 1. Core Architecture Principles
1. **Feature-First Architecture**:
   - Organize code under `lib/features/<feature_name>/` and shared foundational code under `lib/core/`.
   - Subdirectories within each feature represent distinct layers:
     - `presentation/`: UI widgets, screens, dialogs, visual components. Pure rendering and event triggering.
     - `application/`: Riverpod Notifiers, AsyncNotifiers, business logic orchestration, use-case coordinators.
     - `domain/`: Pure Dart entities, value objects, immutable models, repository interfaces. Completely decoupled from Flutter UI and third-party databases.
     - `data/`: Repository implementations, Hive CE data sources, serialization DTOs, TypeAdapters.
2. **On-Demand Layering (Strict Rule)**:
   - **Do NOT create empty stub folders.**
   - Only create a layer directory (`presentation`, `application`, `domain`, `data`) when actual code belonging to that layer exists for the feature.
3. **Clean Separation of UI Logic & Business Logic**:
   - UI widgets must never perform direct database operations, raw file system I/O, or complex business calculations.
   - Business logic must reside in Riverpod Notifiers or domain entities, keeping it 100% testable via pure unit tests without rendering Flutter widgets.

## 2. State Management (Riverpod)
1. **Riverpod with Code Generation**:
   - Use `flutter_riverpod` and `riverpod_annotation` with code generation via `@riverpod` and `riverpod_generator`.
   - Mutable business state and async workflows must be managed by `Notifier` or `AsyncNotifier` classes.
   - UI components consume state using `ConsumerWidget` or `ConsumerStatefulWidget` via `ref.watch()`.
   - Ephemeral UI side effects (e.g., snackbars, dialogs, navigation) must be handled using `ref.listen()`.
   - State models must be immutable and provide `copyWith` methods.

## 3. Local Storage & Android Play Store Compliance
1. **Hive CE (Community Edition)**:
   - Use Hive CE with strongly typed `@HiveType` and `@HiveField` annotations with explicit, unique `typeId`s.
   - The storage engine and any native dependencies must strictly support the **16 KB page-size alignment requirement** of Google Play Store (mandatory for Android 15+). Prefer pure-Dart engines and 16 KB-aligned native libraries.
2. **Path Persistence Rule**:
   - **NEVER** save absolute device paths (e.g., `/data/user/0/...`) in persistent stores or databases.
   - Always store project-relative paths (e.g., `projects/<id>/assets/img_1.png`).
   - Resolve absolute filesystem paths dynamically at runtime using `path_provider`.
3. **Android & Google Play Store Requirements**:
   - Adhere strictly to Scoped Storage and MediaStore APIs; do not use deprecated broad storage permissions.
   - Target modern Android SDK versions and comply with 64-bit architecture requirements.
   - Set required `minSdkVersion` (e.g., 21+ for ML Kit).
4. **Concurrency & Thread Safety**:
   - Any raw byte manipulation, image decoding, filtering, pixel processing, or ML inference **MUST** execute in background isolates via `compute()` or `Isolate.run()`.
   - Never block the main UI thread.

## 4. Static Analysis & Code Quality
1. **Zero Errors, Zero Warnings**:
   - Every code modification must pass `flutter analyze` with **0 errors and 0 warnings**.
   - Keep `analysis_options.yaml` configured for strict typing and lints.
2. **Build Runner Synchronization**:
   - Run `dart run build_runner build --delete-conflicting-outputs` whenever annotations (`@riverpod`, `@HiveType`, etc.) change.
3. **No Incomplete Implementations**:
   - Never leave placeholder comments like `// TODO: implement later`. Complete every implementation fully.

## 5. Comprehensive Testing Mandate
Every implementation or code modification must be accompanied by appropriate automated tests:
1. **Unit Tests (`test/features/<feature>/...`)**:
   - Required for all business logic, Riverpod Notifiers, domain entities, `copyWith` behavior, and serialization/deserialization.
2. **Widget Tests (`test/features/<feature>/presentation/...`)**:
   - Required for UI widgets and screens to verify correct rendering, user interaction (taps, drags, text entry), and visual state transitions (loading, error, success).
3. **Integration / Mock Tests**:
   - Multi-layer flows, repositories, and platform services must be verified using mock dependencies (e.g., `mocktail`).

## 6. Planning, Dependency & Ambiguity Protocols
1. **Plan First**:
   - Always prepare and present a clear plan before implementing any change that is not minor and obvious.
2. **Dependency Gate**:
   - **NEVER** add any new dependency or package to `pubspec.yaml` without asking the user and obtaining explicit approval first.
3. **Clarification Gate**:
   - Always ask clarifying questions before implementing any feature in ambiguous fields or requirements instead of making assumptions or guessing unilaterally.

## 7. Version Control & Git Commit Standards
1. **Commit Every Change**:
   - Make an appropriate Git commit after any and every change or implementation is completed and verified.
2. **Industry-Standard Commit Format (Conventional Commits)**:
   - Use standard Conventional Commits: `<type>(<scope>): <description>`
   - Types:
     - `feat`: New feature or capability.
     - `fix`: Bug fix.
     - `test`: Adding or modifying tests.
     - `refactor`: Code restructuring without external behavior changes.
     - `chore`: Tooling, configuration, build script, or dependency update.
     - `docs`: Documentation, guidelines, or prompt updates.
   - Message style: Clear, imperative, and descriptive (e.g., `feat(canvas): implement project model and hive adapters`).
3. **Verification Before Commit**:
   - Verify that `flutter analyze` passes with 0 errors and 0 warnings and relevant tests pass before committing.
