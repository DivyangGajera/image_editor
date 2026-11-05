import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';
import 'package:image_editor/features/projects/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();

  final container = ProviderContainer();
  // Register installed fonts before the first frame, so saved text renders
  // in its font immediately. A failure must not prevent the app from starting.
  try {
    await container.read(fontLibraryProvider.future);
  } catch (error, stackTrace) {
    AppLogger.error('Font library failed to load', tag: 'Fonts', error: error, stackTrace: stackTrace);
  }

  // Ask Google Play services for the background-removal model early, so it
  // is usually downloaded before the user first needs it.
  unawaited(
    container.read(subjectModelInstallerProvider).ensureModel().then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) => AppLogger.error(
        'Background removal model unavailable',
        tag: 'Segmentation',
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OfflineImageEditorApp(),
    ),
  );
}

/// Root application widget for Chitred.
class OfflineImageEditorApp extends StatelessWidget {
  const OfflineImageEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
