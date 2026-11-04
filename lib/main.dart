import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/projects/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(
    const ProviderScope(
      child: OfflineImageEditorApp(),
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
