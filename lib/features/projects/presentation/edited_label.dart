/// Formats when a project was last edited, relative to [now]:
/// "Edited just now", "Edited 5 min ago", "Edited 3 h ago",
/// "Edited yesterday", "Edited 4 days ago", or "Edited 12 Oct 2026".
String editedLabel(DateTime editedAt, DateTime now) {
  final elapsed = now.difference(editedAt);
  if (elapsed.inMinutes < 1) return 'Edited just now';
  if (elapsed.inMinutes < 60) return 'Edited ${elapsed.inMinutes} min ago';

  final today = DateTime(now.year, now.month, now.day);
  final editedDay = DateTime(editedAt.year, editedAt.month, editedAt.day);
  final daysAgo = today.difference(editedDay).inDays;

  if (daysAgo == 0) return 'Edited ${elapsed.inHours} h ago';
  if (daysAgo == 1) return 'Edited yesterday';
  if (daysAgo < 7) return 'Edited $daysAgo days ago';

  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return 'Edited ${editedAt.day} ${months[editedAt.month - 1]} ${editedAt.year}';
}
