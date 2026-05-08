import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Format a date with the user's preferred format, with smart "Today"/"Yesterday" prefix.
String formatDateSmart(DateTime date, [String? pattern]) {
  final p = pattern ?? _datePattern;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;

  final formatted = DateFormat(p).format(date);
  if (diff == 0) return 'Today, $formatted';
  if (diff == 1) return 'Yesterday, $formatted';
  return formatted;
}
