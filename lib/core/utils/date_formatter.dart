import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _arabicDateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _arabicDateWithDay = DateFormat('EEEE، d MMMM yyyy', 'ar');
  static final DateFormat _timeFormat = DateFormat('hh:mm a', 'ar');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    try {
      return _arabicDateFormat.format(date);
    } catch (_) {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  static String formatDateWithDay(DateTime? date) {
    if (date == null) return '-';
    try {
      return _arabicDateWithDay.format(date);
    } catch (_) {
      return formatDate(date);
    }
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    try {
      return _timeFormat.format(date);
    } catch (_) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    try {
      return _dateTimeFormat.format(date);
    } catch (_) {
      return '${formatDate(date)} ${formatTime(date)}';
    }
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return formatDate(date);
  }

  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes > 0) ? (bytes.toString().length - 1) ~/ 3 : 0;
    if (i >= suffixes.length) i = suffixes.length - 1;
    double num = bytes / (1 << (i * 10));
    return "${num.toStringAsFixed(decimals)} ${suffixes[i]}";
  }
}
