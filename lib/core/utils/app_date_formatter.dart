/// Dedicated Indonesian date formatter that never throws [LocaleDataException]
/// even if intl locale symbols are not yet initialized or when running in tests.
class AppDateFormatter {
  static const List<String> _monthsIndonesian = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _daysIndonesian = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Format as "28 September 2026"
  static String formatLong(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthName = _monthsIndonesian[date.month - 1];
    return '$day $monthName ${date.year}';
  }

  /// Format as "28 September 2026 • 10:24"
  static String formatLongWithTime(DateTime date) {
    final longDate = formatLong(date);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$longDate • $hour:$minute';
  }

  /// Format as "28/09/2026"
  static String formatShort(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  /// Format as "28/09/2026 10:24"
  static String formatShortWithTime(DateTime date) {
    final shortDate = formatShort(date);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$shortDate $hour:$minute';
  }

  /// Format as "Senin, 28 September 2026"
  static String formatDayAndDate(DateTime date) {
    final dayName = _daysIndonesian[date.weekday - 1];
    return '$dayName, ${formatLong(date)}';
  }

  /// Format as "14:32" (time only)
  static String formatTimeOnly(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
