import 'dart:convert';

import '../util/constants.dart';
// import 'sqlite.dart';

class Channel {
  int? id;
  String url;
  String? title;
  String? subtitle;
  String? author;
  String? categories;
  String? description;
  String? language;
  String? link;
  DateTime? updated;
  DateTime? published;
  DateTime? checked;
  int? period;
  String? imageUrl;
  Map<String, dynamic>? extras;

  Channel({
    this.id,
    required this.url,
    this.title,
    this.subtitle,
    this.author,
    this.categories,
    this.description,
    this.language,
    this.link,
    this.updated,
    this.published,
    this.checked,
    this.period,
    this.imageUrl,
    this.extras,
  });

  factory Channel.fromPCIndex(Map<String, dynamic> data) {
    final lastUpdateSec =
        data['lastUpdateTime'] ?? data['newestItemPublishTime'];

    if (data['url'] is String && data['url'].isNotEmpty) {
      return Channel(
        id: data['url'].hashCode,
        title: data['title'],
        url: data['url'],
        link: data['link'],
        description: data['description'],
        author: data['author'],
        imageUrl: data['image'],
        language: data['language'],
        updated:
            lastUpdateSec != null && lastUpdateSec is int
                ? DateTime.fromMillisecondsSinceEpoch(
                  lastUpdateSec * 1000,
                  isUtc: true,
                )
                : null,
        checked: DateTime.now(),
        period: defaultUpdatePeriod,
        categories: data['categories']?.entries
            .map((e) => e.value.toString())
            .join(','),
        extras: {
          'id': data['id'],
          'itunesId': data['itunesId'],
          'explicit': data['explicit'],
          'episodeCount': data['episodeCount'],
        },
      );
    }
    throw Exception({"message": "invalid data from PodcastIndex: no url"});
  }

  factory Channel.fromSqlite(Map<String, Object?> row) {
    return Channel(
      id: row['id'] as int,
      url: row['url'] as String,
      title: row['title'] as String?,
      subtitle: row['subtitle'] as String?,
      author: row['author'] as String?,
      categories: row['categories'] as String?,
      description: row['description'] as String?,
      language: row['language'] as String?,
      link: row['link'] as String?,
      updated:
          row['updated'] != null
              ? DateTime.tryParse(row['updated'] as String)
              : null,
      published:
          row['published'] != null
              ? DateTime.tryParse(row['published'] as String)
              : null,
      checked:
          row['checked'] != null
              ? DateTime.tryParse(row['checked'] as String)
              : null,
      period: row['period'] != null ? row['period'] as int : null,
      imageUrl: row['image_url'] as String?,
      extras:
          row['extras'] != null ? jsonDecode(row['extras'] as String) : null,
    );
  }

  Map<String, Object?> toSqlite() {
    return {
      "id": id,
      "url": url,
      "title": title,
      "subtitle": subtitle,
      "author": author,
      "categories": categories,
      "description": description,
      "language": language,
      "link": link,
      "updated": updated?.toIso8601String(),
      "published": published?.toIso8601String(),
      "checked": checked?.toIso8601String(),
      "period": period,
      "image_url": imageUrl,
      "extras": extras != null ? jsonEncode(extras) : null,
    };
  }

  @override
  String toString() =>
      (toSqlite()
            ..remove('subtitle')
            ..remove('description'))
          .toString();
  /*
  @override
  String toString() {
    return {
      "id": id,
      "url": url,
      "title": title,
      // "subtitle": subtitle?.substring(0, 20),
      "author": author,
      "categories": categories,
      // "description": description?.substring(0, 20),
      "language": language,
      "link": link,
      "updated": updated?.toIso8601String(),
      "published": published?.toIso8601String(),
      "checked": checked?.toIso8601String(),
      "period": period,
      "imageUrl": imageUrl,
      "extras": extras,
    }.toString();
  }
*/
}
