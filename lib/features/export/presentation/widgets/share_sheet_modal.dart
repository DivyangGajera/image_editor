import 'dart:io';
import 'package:flutter/material.dart';

/// Modal sheet presented upon successful export displaying image details and status.
class ShareSheetModal extends StatelessWidget {
  const ShareSheetModal({
    super.key,
    required this.savedFilePath,
  });

  final String savedFilePath;

  /// Convenience helper to display this modal bottom sheet.
  static Future<void> show(BuildContext context, {required String savedFilePath}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareSheetModal(savedFilePath: savedFilePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border(
          top: BorderSide(color: Color(0xFF2E2E40), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(height: 20.0),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4CAF50),
            size: 54.0,
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Export Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Saved to your local gallery / pictures directory',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.0,
            ),
          ),
          const SizedBox(height: 16.0),
          // Thumbnail / Path Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFF2E2E40)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(savedFilePath),
                    width: 48.0,
                    height: 48.0,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => Container(
                      width: 48.0,
                      height: 48.0,
                      color: const Color(0xFF2A2A3C),
                      child: const Icon(Icons.image, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Saved At',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        savedFilePath,
                        style: const TextStyle(
                          color: Color(0xFF4E95FF),
                          fontSize: 12.0,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            height: 46.0,
            child: ElevatedButton(
              key: const ValueKey('share_sheet_done_button'),
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E95FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
