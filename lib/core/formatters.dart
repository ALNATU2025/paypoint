/// Small formatting helpers with no extra package dependencies.
class Fmt {
  Fmt._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 19000 -> "₦ 19,000"
  static String naira(num amount, {bool kobo = false}) {
    final whole = amount.truncate();
    final digits = whole.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    final sign = whole < 0 ? '-' : '';
    final tail = kobo
        ? '.${((amount - whole).abs() * 100).round().toString().padLeft(2, '0')}'
        : '';
    return '₦ $sign$buf$tail';
  }

  /// "26 Nov 2026"
  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// "4:12 PM"
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Today, 4:12 PM" / "02 Oct, 9:40 AM"
  static String shortDateTime(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final sameDay = d.year == n.year && d.month == n.month && d.day == n.day;
    if (sameDay) return 'Today, ${time(d)}';
    return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}, ${time(d)}';
  }

  /// "7012345678" -> "7012 3456 78"
  static String smartcard(String raw) {
    final s = raw.replaceAll(RegExp(r'\s'), '');
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i == 4 || i == 8) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
