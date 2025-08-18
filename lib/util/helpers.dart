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

const _month = [
  "inv", // 0
  "Jan", // 1
  "Feb", // 2
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec", // 12
];

String _twoDigit(int i) {
  return i.toString().padLeft(2, '0');
}

String mmddHHMM(DateTime? dt, {String fallback = ''}) {
  final lo = dt?.toLocal();
  return lo != null
      ? '${_month[lo.month]} ${_twoDigit(lo.day)} ${_twoDigit(lo.hour)}:${_twoDigit(lo.minute)}'
      : fallback;
}

String? googleFaviconUrl(String? url) {
  if (url != null) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return "https://www.google.com/s2/favicons?domain=${uri.host}&sz=128";
    }
  }
  return null;

  // String? domain = url
  //     ?.replaceFirst("https://", "")
  //     .replaceFirst("http://", "")
  //     .split("/")
  //     .first;

  // return domain != null
  //     ? "https://www.google.com/s2/favicons?domain=$domain&sz=128"
  //     : null;
}
