import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/features/collage/collage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
      ),
      home: const ImageEditorHomeScreen(),
    );
  }
}

/// Initial placeholder workspace screen for Phase 1.
class ImageEditorHomeScreen extends StatelessWidget {
  const ImageEditorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.photo_size_select_actual_outlined,
              size: 64.0,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Offline Canvas Ready',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Select or create a project to start editing',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              key: const ValueKey('open_collage_setup_button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CollageSetupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_mosaic_outlined),
              label: const Text('Collage & Filmstrip Maker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E95FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
