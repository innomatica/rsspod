import 'package:html/parser.dart' as parser;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import '../util/constants.dart' show dataRetentionPeriod;
import '../util/helpers.dart' show googleFaviconUrl;
import 'channel.dart';
import 'episode.dart';

class Feed {
  Channel channel;
  List<Episode> episodes;

  Feed({required this.channel, required this.episodes});

  // ignore: unused_field
  static final _logger = Logger('Feed');

  @override
  String toString() {
    return {
      channel: channel.toString(),
      episodes: episodes.map((e) => e.toString).toList(),
    }.toString();
  }

  // RSS: https://www.rssboard.org/rss-specification
  factory Feed.fromRss(XmlElement root, String url) {
    _logger.fine('rss');
    final chnlElem = root.getElement('channel');
    final namespaces = root.attributes
        .where((e) => e.name.prefix == 'xmlns')
        .map((e) => e.name.local)
        .toList();
    // print('namespaces:$namespaces');
    Channel channel = Channel(
      id: url.hashCode,
      url: url,
      title: chnlElem?.getElement('title')?.innerText,
      categories: chnlElem?.getElement('category')?.innerText,
      description: chnlElem?.getElement('description')?.innerText,
      language: chnlElem?.getElement('language')?.innerText,
      link: chnlElem?.getElement('link')?.innerText,
      updated: _parseRFC822(chnlElem?.getElement('lastBuildDate')?.innerText),
      published: _parseRFC822(chnlElem?.getElement('pubDate')?.innerText),
      checked: DateTime.now(),
      imageUrl: chnlElem?.getElement('image')?.getElement('url')?.innerText,
      extras: {},
    );
    // apply namespaces
    channel = _applyNamespaces(channel, namespaces, chnlElem);

    // do not support svg
    if (channel.imageUrl?.endsWith('svg') == true) channel.imageUrl = null;
    // fallback channel image
    channel.imageUrl = channel.imageUrl ?? googleFaviconUrl(channel.link);
    // fallback channel update period
    channel.period = channel.period ?? 1;
    // print('channel:$channel');

    // items
    final itemElems = chnlElem?.findAllElements('item');
    final episodes = <Episode>[];
    DateTime? latest;
    final today = DateTime.now();
    Duration maxDaysAgo = Duration(days: dataRetentionPeriod);

    if (itemElems != null) {
      for (final itemElem in itemElems) {
        // guid must exist and should be unique
        final guid =
            itemElem.getElement('guid')?.innerText ??
            itemElem.getElement('enclosure')?.getAttribute('url');
        // do not collect episode if has no guid
        if (guid == null) continue;

        Episode episode = Episode(
          id: guid.hashCode,
          guid: guid,
          title: itemElem.getElement('title')?.innerText.trim(),
          description: itemElem.getElement('description')?.innerText,
          categories: itemElem
              .findAllElements('category')
              .map((e) => e.innerText)
              .join(','),
          published:
              _parseRFC822(itemElem.getElement('pubDate')?.innerText) ??
              DateTime.now(),
          author: itemElem.getElement('author')?.innerText,
          link: itemElem.getElement('link')?.innerText,
          mediaUrl: itemElem.getElement('enclosure')?.getAttribute('url'),
          mediaType: itemElem.getElement('enclosure')?.getAttribute('type'),
          mediaSize: int.tryParse(
            itemElem.getElement('enclosure')?.getAttribute('length') ?? '',
          ),
          language: channel.language,
          extras: {},
        );
        // apply namespaces
        episode = _applyNamespaces(episode, namespaces, itemElem);

        // the first published is the latest
        latest = latest ?? episode.published;
        // only care within retention period
        if (today.difference(episode.published) > maxDaysAgo) {
          continue;
        }
        // when link is null use channel link
        episode.link = episode.link ?? channel.link;
        // get image from description
        final doc = parser.parse(episode.description ?? '');
        // print('mediaUrl:${episode.mediaUrl}');
        // print('imageUrl:${episode.imageUrl}');
        episode.imageUrl =
            doc.querySelector("img")?.attributes["src"] ??
            (episode.mediaType?.contains('image') == true
                ? episode.mediaUrl
                : null) ??
            episode.imageUrl;
        // print('episode:$episode');
        episodes.add(episode);
      }
    }
    // latest episode.updated has priority over channelupdated
    channel.updated = latest ?? channel.updated ?? DateTime.now();
    return Feed(channel: channel, episodes: episodes);
  }

  // ATOM: https://datatracker.ietf.org/doc/html/rfc4287
  factory Feed.fromAtom(XmlElement root, String url) {
    _logger.fine('atom');
    final namespaces = root.attributes
        .where((e) => e.name.prefix == 'xmlns')
        .map((e) => e.name.local)
        .toList();
    // print('namespaces:$namespaces');
    Channel channel = Channel(
      id: url.hashCode,
      url: url,
      title: root.getElement('title')?.innerText,
      subtitle: root.getElement('subtitle')?.innerText,
      link: root.getElement('link')?.getAttribute('href') ?? url,
      author: root.getElement('author')?.getElement('name')?.innerText,
      categories: root
          .findElements('category')
          .map((e) => e.getAttribute('term') ?? '')
          .toList()
          .join(','),
      imageUrl: root.getElement('logo')?.innerText,
      updated: root.getElement('updated') != null
          ? DateTime.tryParse(root.getElement('updated')!.innerText)
          : null,
      checked: DateTime.now(),
      extras: {},
    );
    // apply namespaces
    channel = _applyNamespaces(channel, namespaces, root);

    // do not accept svg favicon at the moment
    if (channel.imageUrl?.endsWith("svg") == true) channel.imageUrl = null;
    // fallback channel image
    channel.imageUrl = channel.imageUrl ?? googleFaviconUrl(channel.link);
    // fallback channel update period
    channel.period = channel.period ?? 1;
    // print('channel:$channel');

    // entries
    final entries = root.findAllElements('entry');
    final episodes = <Episode>[];
    DateTime? latest;
    final today = DateTime.now();
    Duration maxDaysAgo = Duration(days: dataRetentionPeriod);

    for (final entry in entries) {
      // guid must exist and be unique
      final guid = entry.getElement('id')?.innerText;
      // do not collect episode if has no guid
      if (guid == null) continue;

      Episode episode = Episode(
        id: guid.hashCode,
        guid: guid,
        title: entry.getElement('title')?.innerText,
        subtitle: entry.getElement('summary')?.innerText,
        author: entry.getElement('author')?.getElement('name')?.innerText,
        description: entry.getElement('content')?.innerText,
        categories: entry
            .findElements('category')
            .map((e) => e.getAttribute('term') ?? '')
            .toList()
            .join(','),
        link: entry.getElement('link')?.getAttribute('href'),
        updated: DateTime.tryParse(
          entry.getElement('updated')?.innerText ?? '',
        ),
        published:
            DateTime.tryParse(entry.getElement('published')?.innerText ?? '') ??
            DateTime.tryParse(entry.getElement('updated')?.innerText ?? '') ??
            DateTime.now(),
        extras: {},
      );
      // apply namespaces
      episode = _applyNamespaces(episode, namespaces, entry);
      // the first published is the latest
      latest = latest ?? episode.published;
      // only care within retention period
      if (today.difference(episode.published) > maxDaysAgo) {
        continue;
      }
      // when link is null use channel link
      episode.link = episode.link ?? channel.link;
      // get image from description
      final doc = parser.parse(episode.description ?? '');
      // print('mediaUrl:${episode.mediaUrl}');
      // print('imageUrl:${episode.imageUrl}');
      episode.imageUrl =
          doc.querySelector("img")?.attributes["src"] ??
          (episode.mediaType?.contains('image') == true
              ? episode.mediaUrl
              : null) ??
          episode.imageUrl;
      // print('episode: $episode');
      episodes.add(episode);
    }
    // latest episode.updated has priority over channelupdated
    channel.updated = latest ?? channel.updated ?? DateTime.now();
    return Feed(channel: channel, episodes: episodes);
  }

  // RDF (RSS 1.0): https://web.resource.org/rss/1.0/spec
  factory Feed.fromRdf(XmlElement root, String url) {
    _logger.fine('rdf');
    final namespaces = root.attributes
        .where((e) => e.name.prefix == 'xmlns')
        .map((e) => e.name.local)
        .toList();
    // print('namespaces:$namespaces');
    final chnlElem = root.getElement('channel');
    Channel channel = Channel(
      id: url.hashCode,
      url: url,
      title: root.getElement('title')?.innerText,
      link: root.getElement('link')?.innerText,
      description: root.getElement('description')?.innerText,
      imageUrl: root.getElement('image')?.getAttribute('rdf:resurce'),
    );
    // apply namespaces
    channel = _applyNamespaces(channel, namespaces, chnlElem);

    // do not support svg
    if (channel.imageUrl?.endsWith('svg') == true) channel.imageUrl = null;
    // fallback channel image
    channel.imageUrl = channel.imageUrl ?? googleFaviconUrl(channel.link);
    // fallback channel update period
    channel.period = channel.period ?? 1;
    // print('channel:$channel');

    // items
    final itemElems = chnlElem?.findAllElements('item');
    final episodes = <Episode>[];
    DateTime? latest;
    final today = DateTime.now();
    Duration maxDaysAgo = Duration(days: dataRetentionPeriod);

    if (itemElems != null) {
      for (final itemElem in itemElems) {
        final guid =
            itemElem.getElement('link')?.innerText ??
            itemElem.getElement('url')?.innerText;
        if (guid == null) continue;

        Episode episode = Episode(
          id: guid.hashCode,
          guid: guid,
          title: itemElem.getElement('title')?.innerText.trim(),
          description: itemElem.getElement('description')?.innerText,
          link: itemElem.getElement('link')?.innerText,
          published: DateTime.now(),
          language: channel.language,
          extras: {},
        );
        // apply namespaces
        episode = _applyNamespaces(episode, namespaces, itemElem);

        // the first published is the latest
        latest = latest ?? episode.published;
        // only care within retention period
        if (today.difference(episode.published) > maxDaysAgo) {
          continue;
        }
        // when link is null use channel link
        episode.link = episode.link ?? channel.link;
        // get image from description
        final doc = parser.parse(episode.description ?? '');
        // print('mediaUrl:${episode.mediaUrl}');
        // print('imageUrl:${episode.imageUrl}');
        episode.imageUrl =
            doc.querySelector("img")?.attributes["src"] ??
            (episode.mediaType?.contains('image') == true
                ? episode.mediaUrl
                : null) ??
            episode.imageUrl;
        // print('episode:$episode');
        episodes.add(episode);
      }
    }
    // latest episode.updated has priority over channelupdated
    channel.updated = latest ?? channel.updated ?? DateTime.now();
    return Feed(channel: channel, episodes: episodes);
  }

  static int? _parseItunesDuration(String? data) {
    if (data != null) {
      if (data.contains(":")) {
        // duration in hh:mm:ss format
        final segs = data.split(':');
        if (segs.length == 3) {
          return (int.tryParse(segs[0]) ?? 0) * 3600 +
              (int.tryParse(segs[1]) ?? 0) * 60 +
              (int.tryParse(segs[2]) ?? 0);
        }
      } else {
        // duration in seconds
        return int.tryParse(data);
      }
    }
    return null;
  }

  static dynamic _applyNamespaces(
    dynamic chnOrEps,
    List<String> namespaces,
    XmlElement? element,
  ) {
    // namespace: content (http://purl.org/rss/1.0/modules/content/)
    if (namespaces.contains('content')) {
      // description
      chnOrEps.description =
          chnOrEps.description ??
          element?.getElement('content:encoded')?.innerText;
    }
    // namespace: atom (http://www.w3.org/2005/Atom)
    if (chnOrEps is Channel && namespaces.contains('atom')) {
      // feed url (atom:link href)
      chnOrEps.url =
          element?.getElement('atom:link')?.getAttribute('href') ??
          chnOrEps.url;
      // id has to be updated
      chnOrEps.id = chnOrEps.url.hashCode;
    }
    // namespace: dc
    if (namespaces.contains('dc')) {
      // author
      chnOrEps.author =
          element?.getElement('dc:creator')?.innerText ?? chnOrEps.author;
      // description
      chnOrEps.description =
          element?.getElement("dc:content")?.innerText ?? chnOrEps.description;
      // published
      chnOrEps.published =
          _parseRFC822(element?.getElement('dc:date')?.innerText) ??
          chnOrEps.published;
    }
    // namespace: itunes
    if (namespaces.contains('itunes')) {
      // title
      chnOrEps.title =
          element?.getElement('itunes:title')?.innerText ?? chnOrEps.title;
      // subtitle
      chnOrEps.subtitle =
          element?.getElement('itunes:subtitle')?.innerText ??
          chnOrEps.subtitle;
      // author (itunes:author)
      chnOrEps.author =
          element?.getElement('itunes:author')?.innerText ?? chnOrEps.author;
      // categories (itunes:category)
      chnOrEps.categories =
          element
              ?.findAllElements('itunes:category')
              .map((e) => e.getAttribute('text') ?? '')
              .toList()
              .join(',') ??
          chnOrEps.categories;
      // description (itunes:summary)
      chnOrEps.description =
          element?.getElement('itunes:summary')?.innerText ??
          chnOrEps.description;
      // image url (itunes:image)
      chnOrEps.imageUrl =
          element?.getElement('itunes:image')?.getAttribute('href') ??
          chnOrEps.imageUrl;

      if (chnOrEps is Episode) {
        // keywords
        chnOrEps.keywords =
            element?.getElement('itunes:keywords')?.innerText ??
            chnOrEps.keywords;
        // duration
        chnOrEps.mediaDuration =
            _parseItunesDuration(
              element?.getElement('itunes:duration')?.innerText,
            ) ??
            chnOrEps.mediaDuration;
      } else {
        // feed url (itunes:new-feed-url)
        chnOrEps.url =
            element?.getElement('itunes:new-feed-url')?.innerText ??
            chnOrEps.url;
      }
    }
    // namespace: media (http://search.yahoo.com/mrss/)
    if (chnOrEps is Episode && namespaces.contains('media')) {
      // When it comes to media, rss enclosure has the priority:
      // replace media info ONLY if enclosure is null
      chnOrEps.mediaUrl =
          chnOrEps.mediaUrl ??
          element?.getElement('media:content')?.getAttribute('url') ??
          element?.getElement('media:thumbnail')?.getAttribute('url');
      chnOrEps.mediaType =
          chnOrEps.mediaType ??
          element?.getElement('media:content')?.getAttribute('medium') ??
          (element?.getElement('media:thumbnail')?.getAttribute('url') != null
              ? 'image'
              : null);
      chnOrEps.mediaSize =
          chnOrEps.mediaSize ??
          int.tryParse(
            element?.getElement('media:content')?.getAttribute('width') ?? '',
          ) ??
          int.tryParse(
            element?.getElement('media:thumbnail')?.getAttribute('width') ?? '',
          );
    }
    // namespace: sy (http://purl.org/rss/1.0/modules/syndication/)
    if (namespaces.contains('sy')) {
      final period = element?.getElement('sy:updatePeriod')?.innerText;
      final freq = int.tryParse(
        element?.getElement('sy:updateFrequency')?.innerText ?? '',
      );
      if (period != null && freq != null) {
        switch (period) {
          case "hourly":
            chnOrEps.period = (freq + 23) ~/ 24;
          case "daily":
            chnOrEps.period = freq;
          case "weekly":
            chnOrEps.period = freq * 7;
          case "monthly":
            chnOrEps.period = freq * 30;
          case "quarterly":
            chnOrEps.period = freq * 120;
          case "half yearly":
            chnOrEps.period = freq * 180;
          case "yearly":
            chnOrEps.period = freq * 360;
        }
      }
    }
    return chnOrEps;
  }

  // RFC822: https://datatracker.ietf.org/doc/html/rfc822
  // Warning this does not observe all timezone abbrs
  static DateTime? _parseRFC822(String? rfc822) {
    if (rfc822 == null) return null;
    const m = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12',
    };
    // note: three word timezone is NOT unique, e.g. CST
    const tzmap = {
      "GMT": "+00:00",
      "AST": "-04:00",
      "CDT": "-05:00",
      "CST": "-06:00",
      "EDT": "-04:00",
      "EST": "-05:00",
      "KST": "+09:00",
      "MDT": "-06:00",
      "MST": "-07:00",
      "PDT": "-07:00",
      "PST": "-08:00",
      "UTC": "+00:00",
    };
    // check if it starts with day
    if ([
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ].contains(rfc822.split(",").first)) {
      // potentially legit RFC822
      // Fri, 25 Apr 2025 14:00:00 +0000
      final s = tzmap.entries
          .fold(rfc822, (prev, e) => prev.replaceAll(e.key, e.value))
          .split(' ');
      return DateTime.tryParse(
        '${s[3]}-${m[s[2]]}-${s[1].padLeft(2, '0')}T${s[4]}${s[5]}',
      );
    } else {
      // some feeds use ISO8601 instead
      return DateTime.tryParse(rfc822);
    }
  }
}
