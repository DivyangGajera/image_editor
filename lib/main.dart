import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/theme/app_theme.dart';
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
      theme: AppTheme.light(),
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
            FilledButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }
}
