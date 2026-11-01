String relativeTime(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    final weeks = diff.inDays ~/ 7;
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }
  final months = diff.inDays ~/ 30;
  return '$months month${months == 1 ? '' : 's'} ago';
}
