import 'dart:convert';

import 'package:rsspod/util/constants.dart';

// import '../util/constants.dart';

class Channel {
  int id;
  String url;
  String? title;
  String? subtitle;
  String? author;
  String? categories;
  String? description;
  String? language;
  String? link;
  DateTime? published;
  DateTime? updated;
  DateTime? checked;
  int? period;
  String? imageUrl;
  Map<String, dynamic>? extras;

  Channel({
    required this.id,
    required this.url,
    this.title,
    this.subtitle,
    this.author,
    this.categories,
    this.description,
    this.language,
    this.link,
    this.published,
    this.updated,
    this.checked,
    this.period,
    this.imageUrl,
    this.extras,
  });

  String get imagePath => "$appDocPath/$id/$chnImgFname";

  factory Channel.fromPCIndex(Map<String, dynamic> data) {
    final lastUpdateSec =
        data['newestItemPublishTime'] ?? data['lastUpdateTime'];

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
        updated: lastUpdateSec != null && lastUpdateSec is int
            ? DateTime.fromMillisecondsSinceEpoch(
                lastUpdateSec * 1000,
                isUtc: true,
              )
            : DateTime.now(),
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
      updated: DateTime.tryParse(row['updated'] as String? ?? ''),
      published: DateTime.tryParse(row['published'] as String? ?? ''),
      checked: DateTime.tryParse(row['checked'] as String? ?? ''),
      period: row['period'] as int?,
      imageUrl: row['image_url'] as String?,
      extras: jsonDecode(row['extras'] as String? ?? "null"),
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
      "extras": jsonEncode(extras),
    };
  }

  @override
  String toString() =>
      (toSqlite()
            ..remove('subtitle')
            ..remove('description'))
          .toString();
}
