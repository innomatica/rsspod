import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../model/channel.dart';
import '../../../model/pcindex.dart';
import '../../../util/constants.dart';
import '../../../util/secrets.dart';

// https://podcastindex-org.github.io/docs-api/
class PCIndexService {
  final _log = Logger("PCIndexService");

  Map<String, String> _getAuthHeader() {
    String time = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    return {
      "User-Agent": "$appId/$appVersion",
      "X-Auth-Key": pcIdxApiKey,
      "X-Auth-Date": time,
      "Authorization":
          sha1.convert(utf8.encode("$pcIdxApiKey$pcIdxSecret$time")).toString(),
    };
  }

  Future<List<Channel>> searchPodcasts(
    PCIndexSearch method,
    String keywords,
  ) async {
    final results = <Channel>[];
    // _log.fine('method:$method, keywords:$keywords');

    String ep = pcIdxEndpoint;
    if (method == PCIndexSearch.byTerm) {
      ep = '$ep/search/byterm';
    } else if (method == PCIndexSearch.byTitle) {
      ep = '$ep/search/bytitle';
    } else {
      ep = '$ep/podcasts/trending';
    }

    final url = Uri.parse("$ep?q=$keywords&max=15");
    try {
      final res = await http.get(url, headers: _getAuthHeader());
      if (res.statusCode == 200) {
        // _log.fine(res.body);
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        // _log.fine(data);
        if (data is Map && data.containsKey('feeds') && data['feeds'] is List) {
          final chs =
              data['feeds']
                  .map<Channel>((e) => Channel.fromPCIndex(e))
                  .toList();
          // _log.fine(chs);
          return chs;
        }
      }
    } catch (e) {
      _log.severe(e.toString());
    }
    return results;
  }
}
