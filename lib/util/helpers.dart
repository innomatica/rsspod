String secsToHhMmSs(int? seconds) {
  if (seconds != null && seconds > 0) {
    final h = seconds ~/ 3600;
    final m = (seconds - h * 3600) ~/ 60;
    final s = (seconds - h * 3600 - m * 60);

    return h > 0
        ? "${h.toString()}h ${m.toString().padLeft(2, '0')}m"
        : m > 0
        ? "${m.toString()}m ${s.toString().padLeft(2, '0')}s"
        : "${s.toString()}s";
  }
  return "??m";
}

String sizeStr(int? size) {
  if (size != null && size > 0) {
    final kb = size ~/ 1000;
    return kb > 1000 ? "${((kb * 10) ~/ 1000) / 10}mb" : "${kb}kb";
  }
  return "??kb";
}

String daysAgo(DateTime? date) {
  if (date != null) {
    final days = DateTime.now().difference(date).inDays;
    return days < 1 ? 'today' : '$days day(s) ago';
  }
  return 'n/a';
}

String yymmdd(DateTime? dt, {String fallback = ''}) {
  return dt?.toIso8601String().split('T').first ?? fallback;
}

String removeTags(String? input) {
  final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return input?.replaceAll(exp, '') ?? '';
}
