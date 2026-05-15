import 'package:intl/intl.dart';

/// API timestamps are usually ISO 8601 with `Z` (UTC). Display Singapore (UTC+8) wall time.
String formatApiDateTimeSingapore(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  try {
    final dt = DateTime.parse(s);
    final utc = dt.toUtc();
    // Singapore has no DST; wall clock = UTC + 8h for the same instant.
    final sgWall = utc.add(const Duration(hours: 8));
    return DateFormat('yyyy-MM-dd HH:mm').format(sgWall);
  } catch (_) {
    return raw;
  }
}
