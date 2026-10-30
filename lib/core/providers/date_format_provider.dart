import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/s_lookup.dart';
import '../../shared/utils/calendar_days.dart';

const _key = 'date_format';

/// Supported date format patterns.
const dateFormatOptions = <String, String>{
  'MMM d, y': 'May 6, 2026',
  'MMMM d': 'May 6',
  'd MMM y': '6 May 2026',
  'd/M/y': '6/5/2026',
  'M/d/y': '5/6/2026',
  'y-MM-dd': '2026-05-06',
};

final dateFormatProvider =
    NotifierProvider<DateFormatNotifier, String>(DateFormatNotifier.new);

class DateFormatNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'MMM d, y';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key);
      if (val != null && dateFormatOptions.containsKey(val)) {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> setFormat(String fmt) async {
    state = fmt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, fmt);
  }
}

/// Global date format pattern, set from the provider via app.dart.
String _datePattern = 'MMM d, y';

/// Called from app.dart to keep the global in sync with the provider.
void setDateFormatPattern(String pattern) {
  _datePattern = pattern;
}

/// Format a date with the user's preferred format.
String formatDate(DateTime date) {
  return DateFormat(_datePattern).format(date);
}

/// The user's date format without the year when the date is in this year
/// ("Oct 29", "29/10"); another year keeps it. ISO dates stay whole.
String formatDateNoYear(DateTime date) {
  if (date.year != DateTime.now().year) return formatDate(date);
  final pattern = switch (_datePattern) {
    'MMM d, y' => 'MMM d',
    'd MMM y' => 'd MMM',
    'd/M/y' => 'd/M',
    'M/d/y' => 'M/d',
    _ => _datePattern,
  };
  return DateFormat(pattern).format(date);
}

/// Format a date with the user's preferred format, with smart "Today"/"Yesterday" prefix.
/// Date in the user's format plus the time (locale's 12/24-hour style),
/// e.g. for backups and sync timestamps.
/// A month name for labels and headers, in the app language, capitalized
/// ("Octobre 2026", not "octobre 2026"): [short] gives "Oct", [year] adds
/// the year. Use instead of DateFormat('MMM'/'MMMM yyyy') in screens.
String formatMonth(DateTime date, {bool short = false, bool year = false}) {
  final f = short
      ? (year ? DateFormat.yMMM() : DateFormat.MMM())
      : (year ? DateFormat.yMMMM() : DateFormat.MMMM());
  final s = f.format(date);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

String formatDateTime(DateTime date) =>
    '${formatDate(date)} ${DateFormat.jm().format(date)}';

String formatDateSmart(DateTime date, [String? pattern]) {
  final p = pattern ?? _datePattern;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = calendarDaysBetween(d, today);

  final formatted = DateFormat(p).format(date);
  if (diff == 0) return '${currentS().commonToday}, $formatted';
  if (diff == 1) return '${currentS().commonYesterday}, $formatted';
  return formatted;
}
