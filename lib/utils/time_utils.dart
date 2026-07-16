import 'package:intl/intl.dart';

String timeAgo(DateTime dateTime, {bool short = false}) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return short ? 'now' : 'Just now';
  if (diff.inMinutes < 60) return short ? '${diff.inMinutes}m' : '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return short ? '${diff.inHours}h' : '${diff.inHours}h ago';
  if (diff.inDays < 7) return short ? '${diff.inDays}d' : '${diff.inDays}d ago';
  return DateFormat('MMM d').format(dateTime);
}
