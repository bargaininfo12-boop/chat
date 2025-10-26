import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// ✅ Unified timestamp utility (UTC-safe + rich formatting)
class TimestampUtils {
  // ---------- Core Conversions (UTC-First) ----------

  /// Any supported input → DateTime (UTC)
  static DateTime toDateTime(dynamic timestamp) {
    try {
      if (timestamp == null) return DateTime.now().toUtc();

      if (timestamp is DateTime) {
        return timestamp.toUtc();
      } else if (timestamp is int) {
        // Check if seconds (< year 2100 in seconds format)
        if (timestamp < 4102444800) {
          // Likely seconds, convert to milliseconds
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
        }
        // Milliseconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
      } else if (timestamp is Timestamp) {
        return timestamp.toDate().toUtc();
      } else if (timestamp is String) {
        // 1) numeric millis/seconds
        final asInt = int.tryParse(timestamp.trim());
        if (asInt != null) {
          if (asInt < 4102444800) {
            return DateTime.fromMillisecondsSinceEpoch(asInt * 1000, isUtc: true);
          }
          return DateTime.fromMillisecondsSinceEpoch(asInt, isUtc: true);
        }
        // 2) ISO-8601 or RFC formats
        try {
          return DateTime.parse(timestamp).toUtc();
        } catch (_) {
          debugPrint("TimestampUtils: Unrecognized string '$timestamp'");
          return DateTime.now().toUtc();
        }
      } else {
        debugPrint("TimestampUtils: Unknown type ${timestamp.runtimeType}");
        return DateTime.now().toUtc();
      }
    } catch (e) {
      debugPrint("TimestampUtils: toDateTime error: $e");
      return DateTime.now().toUtc();
    }
  }

  /// Any supported input → DateTime (Local for display)
  static DateTime toLocalDateTime(dynamic timestamp) {
    return toDateTime(timestamp).toLocal();
  }

  /// Any supported input → millisecondsSinceEpoch (UTC)
  static int toMilliseconds(dynamic timestamp) {
    return toDateTime(timestamp).millisecondsSinceEpoch;
  }

  /// Safe compare for sorting (returns -1/0/1)
  static int compare(dynamic a, dynamic b) {
    try {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      final ma = toMilliseconds(a);
      final mb = toMilliseconds(b);
      return ma.compareTo(mb);
    } catch (e) {
      debugPrint("TimestampUtils: compare error: $e");
      return 0;
    }
  }

  /// Firestore Timestamp from any input (UTC-safe)
  static Timestamp toFirestoreTimestamp(dynamic timestamp) {
    return Timestamp.fromMillisecondsSinceEpoch(toMilliseconds(timestamp));
  }

  /// Current time (ms, UTC)
  static int nowInMilliseconds() => DateTime.now().toUtc().millisecondsSinceEpoch;

  /// Current Firestore Timestamp
  static Timestamp nowFirestoreTimestamp() => Timestamp.now();

  // ---------- Validation ----------

  /// Check if timestamp is valid (not null, not future, within reasonable range)
  static bool isValid(dynamic timestamp, {bool allowFuture = false}) {
    try {
      if (timestamp == null) return false;
      final dt = toDateTime(timestamp);
      final now = DateTime.now().toUtc();

      // Check reasonable range (after year 2000, before year 2100)
      if (dt.year < 2000 || dt.year > 2100) return false;

      // Check future timestamps if not allowed
      if (!allowFuture && dt.isAfter(now)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if timestamp is in future
  static bool isFuture(dynamic timestamp) {
    try {
      final dt = toDateTime(timestamp);
      return dt.isAfter(DateTime.now().toUtc());
    } catch (e) {
      return false;
    }
  }

  // ---------- Simple Formatters (Auto Local Conversion) ----------

  /// For message bubble time, e.g. "02:35 PM"
  static String formatTime(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    return DateFormat('hh:mm a').format(dt);
  }

  /// 24-hour format "14:35"
  static String formatTime24(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    return DateFormat('HH:mm').format(dt);
  }

  /// Date header text (Today / Yesterday / Weekday / MMM dd / MMM dd, yyyy)
  static String formatDate(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    final diff = _safeDiff(now, dt);

    if (isToday(dt)) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays > 1 && diff.inDays < 7) {
      return DateFormat('EEEE').format(dt); // Monday, Tuesday...
    }
    if (dt.year == now.year) {
      return DateFormat('MMM dd').format(dt); // Jan 15
    }
    return DateFormat('MMM dd, yyyy').format(dt); // Jan 15, 2023
  }

  /// Chat list last message compact time
  static String formatLastMessageTime(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    final diff = _safeDiff(now, dt);

    if (isToday(dt)) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return DateFormat('EEE').format(dt); // Mon, Tue
    if (dt.year == now.year) return DateFormat('MMM dd').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }

  /// Last seen text like "Just now", "12m ago", "Wed", "Mar 08"
  static String formatLastSeen(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    final diff = _safeDiff(now, dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMM dd').format(dt);
  }

  /// Notification chip time like "now", "12m", "3h", "1d", or "MMM dd"
  static String formatNotificationTime(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    final diff = _safeDiff(now, dt);

    if (diff.inMinutes < 1) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays == 1) return "1d";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return DateFormat('MMM dd').format(dt);
  }

  /// Detailed label like "Today at 02:35 PM", "Jan 15 at 02:35 PM"
  static String formatDetailed(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    final time = DateFormat('hh:mm a').format(dt);

    if (isToday(dt)) return "Today at $time";
    if (_safeDiff(now, dt).inDays == 1) return "Yesterday at $time";
    if (dt.year == now.year) {
      return "${DateFormat('MMM dd').format(dt)} at $time";
    }
    return "${DateFormat('MMM dd, yyyy').format(dt)} at $time";
  }

  /// Time with explicit UTC offset: "Mar 08, 2025 at 02:35 PM (UTC+05:30)"
  static String formatWithTimeZone(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final base = DateFormat("MMM dd, yyyy 'at' hh:mm a").format(dt);
    final offset = _formatUtcOffset(dt.timeZoneOffset);
    return "$base (UTC$offset)";
  }

  /// Full ISO format with timezone: "2025-03-08T14:35:00.000+05:30"
  static String formatFullISO(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    return dt.toIso8601String();
  }

  // ---------- Relative Checks ----------

  static bool isToday(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool isSameDay(dynamic a, dynamic b) {
    final d1 = toLocalDateTime(a);
    final d2 = toLocalDateTime(b);
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Same week check. By default Monday = start of week.
  /// Set [weekStartsOnMonday] = false for Sunday-start regions.
  static bool isSameWeek(dynamic a, dynamic b, {bool weekStartsOnMonday = true}) {
    final d1 = _startOfWeek(toLocalDateTime(a), weekStartsOnMonday: weekStartsOnMonday);
    final d2 = _startOfWeek(toLocalDateTime(b), weekStartsOnMonday: weekStartsOnMonday);
    return isSameDay(d1, d2);
  }

  static bool isCurrentMonth(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month;
  }

  static bool isWithinLastHour(dynamic timestamp) {
    final dt = toDateTime(timestamp);
    final now = DateTime.now().toUtc();
    return _safeDiff(now, dt).inHours < 1;
  }

  static bool isWithinLast24Hours(dynamic timestamp) {
    final dt = toDateTime(timestamp);
    final now = DateTime.now().toUtc();
    return _safeDiff(now, dt).inHours < 24;
  }

  static bool isWithinLastNDays(dynamic timestamp, int days) {
    final dt = toDateTime(timestamp);
    final now = DateTime.now().toUtc();
    return _safeDiff(now, dt).inDays <= days;
  }

  /// "3 days ago" / "1 hour ago" / "Just now"
  static String getDurationSince(dynamic timestamp) {
    final dt = toDateTime(timestamp);
    final now = DateTime.now().toUtc();
    final diff = _safeDiff(now, dt);

    if (diff.inDays > 0) {
      return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    } else if (diff.inHours > 0) {
      return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

  /// Relative day: Today / Yesterday / Weekday / "January 15" / "January 15, 2023"
  static String getRelativeDay(dynamic timestamp) {
    final dt = toLocalDateTime(timestamp);
    final now = DateTime.now();
    final diff = _safeDiff(now, dt);

    if (isToday(dt)) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
    if (dt.year == now.year) return DateFormat('MMMM dd').format(dt);
    return DateFormat('MMMM dd, yyyy').format(dt);
  }

  // ---------- Chat List / Headers ----------

  /// For reverse-ordered lists (newest first).
  /// Show header when current and previous are on different days.
  static bool shouldShowDateHeader(dynamic currentTimestamp, dynamic previousTimestamp) {
    if (previousTimestamp == null) return true;
    return !isSameDay(currentTimestamp, previousTimestamp);
  }

  // ---------- ISO Helpers ----------

  static String toISOString(dynamic timestamp) {
    return toDateTime(timestamp).toIso8601String();
  }

  static DateTime fromISOString(String isoString) {
    try {
      return DateTime.parse(isoString).toUtc();
    } catch (e) {
      debugPrint("TimestampUtils: ISO parse error for '$isoString'");
      return DateTime.now().toUtc();
    }
  }

  // ---------- Debugging Helpers ----------

  /// Debug print timestamp in all formats
  static void debugTimestamp(dynamic timestamp, {String? label}) {
    try {
      final utc = toDateTime(timestamp);
      final local = toLocalDateTime(timestamp);
      final millis = toMilliseconds(timestamp);

      debugPrint("━━━ ${label ?? 'Timestamp Debug'} ━━━");
      debugPrint("UTC:    $utc");
      debugPrint("Local:  $local");
      debugPrint("Millis: $millis");
      debugPrint("ISO:    ${utc.toIso8601String()}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━");
    } catch (e) {
      debugPrint("TimestampUtils: debug error: $e");
    }
  }

  // ---------- Private helpers ----------

  static Duration _safeDiff(DateTime a, DateTime b) {
    // Protect against negatives if order flips
    final d = a.difference(b);
    return d.isNegative ? Duration(milliseconds: -d.inMilliseconds.abs()) : d;
  }

  static DateTime _startOfWeek(DateTime dt, {required bool weekStartsOnMonday}) {
    // Monday=1 ... Sunday=7
    final weekday = dt.weekday;
    final delta = weekStartsOnMonday ? (weekday - DateTime.monday) : (weekday % 7);
    return DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: delta));
  }

  static String _formatUtcOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final total = offset.inMinutes.abs();
    final hh = (total ~/ 60).toString().padLeft(2, '0');
    final mm = (total % 60).toString().padLeft(2, '0');
    return "$sign$hh:$mm";
  }
}
