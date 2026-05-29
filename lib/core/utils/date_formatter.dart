import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat =
      DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateOnly = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dayMonth = DateFormat('EEEE, d MMM yyyy', 'id_ID');
  static final DateFormat _storedFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeOnly = DateFormat('HH:mm');

  /// Format DateTime to display string: "29 Mei 2025, 14:30"
  static String format(DateTime dt) => _displayFormat.format(dt);

  /// Format DateTime to date only: "29 Mei 2025"
  static String dateOnly(DateTime dt) => _dateOnly.format(dt);

  /// Format with day name: "Kamis, 29 Mei 2025"
  static String withDay(DateTime dt) => _dayMonth.format(dt);

  /// Format for SQLite storage: "2025-05-29"
  static String toStored(DateTime dt) => _storedFormat.format(dt);

  /// Parse stored ISO date "2025-05-29"
  static DateTime? fromStored(String s) {
    try {
      return _storedFormat.parse(s);
    } catch (_) {
      return null;
    }
  }

  /// Format DateTime to time string: "14:30"
  static String timeOnly(DateTime dt) => _timeOnly.format(dt);

  /// Parse ISO timestamp from SQLite CURRENT_TIMESTAMP
  static DateTime? fromIso(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
