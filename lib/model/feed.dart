import 'package:html/parser.dart' as parser;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

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
    final channel = Channel(
      url: url,
      title: chnlElem?.getElement('title')?.innerText,
      // subtitle not part of rss
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
    // namespace: itunes
    if (namespaces.contains('itunes')) {
      // author (override)
      channel.author =
          chnlElem?.getElement('itunes:author')?.innerText ?? channel.author;
      // categories (override)
      channel.categories =
          chnlElem
              ?.findAllElements('itunes:category')
              .map((e) => e.getAttribute('text') ?? '')
              .toList()
              .join(',') ??
          channel.categories;
      // description (override)
      channel.description =
          chnlElem?.getElement('itunes:summary')?.innerText ??
          channel.description;
      // image url (override)
      channel.imageUrl =
          chnlElem?.getElement('itunes:image')?.getAttribute('href') ??
          channel.imageUrl;
    }
    // namespace: atom (http://www.w3.org/2005/Atom)
    if (namespaces.contains('atom')) {
      // replace only when necessar
      channel.link =
          channel.link ??
          chnlElem?.getElement('atom:link')?.getAttribute('href');
    }
    // namespace: sy (http://purl.org/rss/1.0/modules/syndication/)
    if (namespaces.contains('sy')) {
      channel.period = int.tryParse(
        chnlElem?.getElement('sy:updateFrequency')?.innerText ?? '',
      );
    }
    // namespace: content
    // namespace: media

    // do not support svg
    if (channel.imageUrl?.endsWith('svg') == true) {
      channel.imageUrl = null;
    }
    channel.imageUrl = channel.imageUrl ?? googleFaviconUrl(channel.url);
    // print('channel:$channel');

    // items
    final itemElems = chnlElem?.findAllElements('item');
    final episodes = <Episode>[];
    if (itemElems != null) {
      for (final itemElem in itemElems) {
        final guid =
            itemElem.getElement('guid')?.innerText ??
            itemElem.getElement('link')?.innerText ??
            itemElem.getElement('enclosure')?.getAttribute('url');
        // guid must exist and should be unique
        if (guid == null) continue;

        final episode = Episode(
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
        // print('episode:$episode');
        // namespace: content (http://purl.org/rss/1.0/modules/content/)
        if (namespaces.contains('content')) {
          // description
          episode.description =
              itemElem.getElement('content:encoded')?.innerText ??
              episode.description;
        }
        // namespace: dc (http://purl.org/dc/elements/1.1/)
        if (namespaces.contains('dc')) {
          // author
          episode.author =
              itemElem.getElement("dc:creator")?.innerText ?? episode.author;
          // description
          episode.description =
              itemElem.getElement("dc:content")?.innerText ??
              episode.description;
          // date
          episode.published =
              _parseRFC822(itemElem.getElement("dc:date")?.innerText) ??
              episode.published;
        }
        // namespace: itunes
        if (namespaces.contains('itunes')) {
          // author (override)
          episode.author =
              itemElem.getElement('itunes:author')?.innerText ?? episode.author;
          // categories (override)
          episode.categories =
              chnlElem
                  ?.findAllElements('itunes:category')
                  .map((e) => e.getAttribute('text') ?? '')
                  .toList()
                  .join(',') ??
              episode.categories;
          // image url
          episode.imageUrl = itemElem
              .getElement('itunes:image')
              ?.getAttribute('href');
          // subtitle
          episode.subtitle = itemElem.getElement('itunes:subtitle')?.innerText;
          // keywords
          episode.keywords = itemElem.getElement('itunes:keywords')?.innerText;
          // duration
          episode.mediaDuration = int.tryParse(
            itemElem.getElement('itunes:duration')?.innerText ?? '',
          );
        }
        // namespace: media (http://search.yahoo.com/mrss/)
        if (namespaces.contains('media')) {
          episode.mediaUrl =
              itemElem.getElement('media:content')?.getAttribute('url') ??
              itemElem.getElement('media:thumbnail')?.getAttribute('url') ??
              episode.mediaUrl;
          episode.mediaType =
              episode.mediaType ??
              itemElem.getElement('media:content')?.getAttribute('medium') ??
              (itemElem.getElement('media:thumbnail')?.getAttribute('url') !=
                      null
                  ? 'image'
                  : null);
          episode.mediaSize =
              episode.mediaSize ??
              int.tryParse(
                itemElem.getElement('media:content')?.getAttribute('width') ??
                    '',
              ) ??
              int.tryParse(
                itemElem.getElement('media:thumbnail')?.getAttribute('width') ??
                    '',
              );
        }
        // get image from content(description)
        final doc = parser.parse(episode.description ?? '');
        // print('mediaUrl:${episode.mediaUrl}');
        // print('imageUrl:${episode.imageUrl}');
        episode.imageUrl =
            doc.querySelector("img")?.attributes["src"] ??
            (episode.mediaType?.contains('image') == true
                ? episode.mediaUrl
                : null) ??
            episode.imageUrl;
        // _log.fine('item: $episode');
        // print('episode:$episode');
        episodes.add(episode);
      }
    }
    return Feed(channel: channel, episodes: episodes);
  }

  // ATOM: https://datatracker.ietf.org/doc/html/rfc4287
  factory Feed.fromAtom(XmlElement root, String url) {
    // ignore: unused_local_variable
    final namespaces = root.attributes
        .where((e) => e.name.prefix == 'xmlns')
        .map((e) => e.name.local)
        .toList();
    // print('namespaces:$namespaces');
    final channel = Channel(
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
    // do not accept svg favicon at the moment
    if (channel.imageUrl?.endsWith("svg") == true) {
      channel.imageUrl = null;
    }
    channel.imageUrl = channel.imageUrl ?? googleFaviconUrl(channel.url);
    // print('channel:$channel');

    final entries = root.findAllElements('entry');
    final episodes = <Episode>[];
    for (final entry in entries) {
      // guid must exist and be unique
      final guid = entry.getElement('id')?.innerText;
      if (guid == null) continue;
      final episode = Episode(
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
      // print('episode: $episode');
      episodes.add(episode);
    }

    return Feed(channel: channel, episodes: episodes);
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
