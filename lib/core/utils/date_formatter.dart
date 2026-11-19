import 'package:intl/intl.dart';

/// Locale-aware date formatting. API timestamps are ISO-8601 UTC and are
/// shown in the device's local time zone.
class DateFormatter {
  const DateFormatter._();

  static DateTime? parse(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso)?.toLocal();

  static String dateTime(DateTime value, String locale) =>
      DateFormat.yMMMd(locale).add_Hm().format(value.toLocal());

  static String date(DateTime value, String locale) =>
      DateFormat.yMMMd(locale).format(value.toLocal());

  static String time(DateTime value, String locale) =>
      DateFormat.Hm(locale).format(value.toLocal());

  /// `yyyy-MM-dd` used for `from`/`to` query parameters.
  static String apiDate(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);
}
