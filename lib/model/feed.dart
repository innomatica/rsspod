import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import 'channel.dart';
import 'episode.dart';

class Feed {
  Channel channel;
  List<Episode> episodes;

  Feed({required this.channel, required this.episodes});

  // ignore: unused_field
  static final _log = Logger('Feed');

  @override
  String toString() {
    return {
      channel: channel.toString(),
      episodes: episodes.map((e) => e.toString).toList(),
    }.toString();
  }

  // RSS: https://www.rssboard.org/rss-specification
  factory Feed.fromRss(XmlElement root, String url) {
    // _log.fine('rss');
    final chnlElem = root.getElement('channel');
    final namespaces =
        root.attributes
            .where((e) => e.name.prefix == 'xmlns')
            .map((e) => e.name.local)
            .toList();
    final channel = Channel(
      url: url,
      title: chnlElem?.getElement('title')?.innerText,
      // subtitle
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
    // namespace: atom
    // namespace: content
    // namespace: media
    // _log.fine('channel:$channel');

    // items
    final itemElems = chnlElem?.findAllElements('item');
    final episodes = <Episode>[];
    if (itemElems != null) {
      for (final element in itemElems) {
        // guid must exist and should be unique
        final guid =
            element.getElement('guid')?.innerText ??
            element.getElement('link')?.innerText ??
            element.getElement('enclosure')?.getAttribute('url');
        if (guid == null) continue;
        final episode = Episode(
          guid: guid,
          title: element.getElement('title')?.innerText,
          description: element.getElement('description')?.innerText,
          categories: element.getElement('category')?.innerText,
          published: _parseRFC822(element.getElement('pubDate')?.innerText),
          author: element.getElement('author')?.innerText,
          link: element.getElement('link')?.innerText,
          mediaUrl: element.getElement('enclosure')?.getAttribute('url'),
          mediaType: element.getElement('enclosure')?.getAttribute('type'),
          mediaSize: int.tryParse(
            element.getElement('enclosure')?.getAttribute('length') ?? '0',
          ),
          extras: {},
        );
        // namespace: itunes
        if (namespaces.contains('itunes')) {
          // author (override)
          episode.author =
              element.getElement('itunes:author')?.innerText ?? episode.author;
          // categories (override)
          episode.categories =
              chnlElem
                  ?.findAllElements('itunes:category')
                  .map((e) => e.getAttribute('text') ?? '')
                  .toList()
                  .join(',') ??
              episode.categories;
          // image url
          episode.imageUrl = element
              .getElement('itunes:image')
              ?.getAttribute('href');
          // subtitle
          episode.subtitle = element.getElement('itunes:subtitle')?.innerText;
          // keywords
          episode.keywords = element.getElement('itunes:keywords')?.innerText;
          // duration
          final duration = element.getElement('itunes:duration')?.innerText;
          if (duration != null) {
            episode.mediaDuration = int.tryParse(duration);
          }
        }
        // _log.fine('item: $episode');
        episodes.add(episode);
      }
    }
    return Feed(channel: channel, episodes: episodes);
  }

  // ATOM: https://datatracker.ietf.org/doc/html/rfc4287
  factory Feed.fromAtom(XmlElement root, String url) {
    // ignore: unused_local_variable
    final namespaces =
        root.attributes
            .where((e) => e.name.prefix == 'xmlns')
            .map((e) => e.name.local)
            .toList();
    final channel = Channel(
      url: url,
      title: root.getElement('title')?.innerText,
      subtitle: root.getElement('subtitle')?.innerText,
      author: root.getElement('author')?.getElement('name')?.innerText,
      categories: root
          .findElements('category')
          .map((e) => e.getAttribute('term') ?? '')
          .toList()
          .join(','),
      imageUrl: root.getElement('logo')?.innerText,
      updated:
          root.getElement('updated') != null
              ? DateTime.tryParse(root.getElement('updated')!.innerText)
              : null,
      checked: DateTime.now(),
      extras: {},
    );
    // _log.fine('channel:$channel');

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
        updated:
            entry.getElement('updated') != null
                ? DateTime.tryParse(entry.getElement('updated')!.innerText)
                : null,
        published:
            entry.getElement('published') != null
                ? DateTime.tryParse(entry.getElement('published')!.innerText)
                : null,
        extras: {},
      );
      // _log.fine('episode: $episode');
      episodes.add(episode);
    }

    return Feed(channel: channel, episodes: episodes);
  }

  // RFC822: https://datatracker.ietf.org/doc/html/rfc822
  // Warning this does not observe timezone except +0000
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
    // Fri, 25 Apr 2025 14:00:00 +0000
    final s = rfc822.replaceFirst('GMT', '+0000').split(' ');
    return DateTime.tryParse(
      '${s[3]}-${m[s[2]]}-${s[1].padLeft(2, '0')}T${s[4]} ${s[5]}',
    );
  }
}
