import 'dart:convert';

import '../util/constants.dart';

class Episode {
  int id; // db specific: primary key
  String guid;
  String? title;
  String? subtitle;
  String? author;
  String? description;
  String? language;
  String? categories;
  String? keywords;
  DateTime? updated;
  DateTime published;
  String? link;
  String? mediaUrl;
  String? mediaType;
  int? mediaSize;
  int? mediaDuration;
  int? mediaSeekPos;
  String? imageUrl;
  Map<String, dynamic>? extras;
  // internal use
  bool? downloaded;
  bool? played;
  bool? liked;
  // filled after channel save
  int? channelId;
  // db fields
  String? channelUrl;
  String? channelTitle;
  String? channelImageUrl;

  Episode({
    required this.id,
    required this.guid,
    this.title,
    this.subtitle,
    this.author,
    this.description,
    this.language,
    this.categories,
    this.keywords,
    this.updated,
    required this.published,
    this.link,
    this.mediaUrl,
    this.mediaType,
    this.mediaSize,
    this.mediaDuration,
    this.mediaSeekPos,
    this.imageUrl,
    this.extras,
    this.downloaded,
    this.played,
    this.liked,
    // db fields
    this.channelId,
    this.channelUrl,
    this.channelTitle,
    this.channelImageUrl,
  });

  // url could be used as guid
  String get imagePath => "$appDocPath/$channelId/$id";
  String get channelImagePath => "$appDocPath/$channelId/$chnImgFname";
  String get mediaFname => guid.replaceAll('/', '\\');
  String? get imageFname =>
      imageUrl != null ? Uri.tryParse(imageUrl!)?.path.split('/').last : null;

  factory Episode.fromSqlite(Map<String, Object?> row) {
    return Episode(
      id: row['id'] as int,
      guid: row['guid'] as String,
      title: row['title'] as String?,
      subtitle: row['subtitle'] as String?,
      author: row['author'] as String?,
      description: row['description'] as String?,
      language: row['language'] as String?,
      categories: row['categories'] as String?,
      keywords: row['keywords'] as String?,
      updated: DateTime.tryParse(row['updated'] as String? ?? ''),
      published:
          DateTime.tryParse(row['published'] as String? ?? '') ??
          DateTime.now(),
      link: row['link'] as String?,
      mediaUrl: row['media_url'] as String?,
      mediaType: row['media_type'] as String?,
      mediaSize: row['media_size'] as int?,
      mediaDuration: row['media_duration'] as int?,
      mediaSeekPos: row['media_seek_pos'] as int?,
      imageUrl: row['image_url'] as String?,
      extras: jsonDecode(row['extras'] as String? ?? "null"),
      downloaded: row['downloaded'] == 1,
      played: row['played'] == 1,
      liked: row['liked'] == 1,
      // db fields
      channelId: row['channel_id'] as int?,
      channelUrl: row['channel_url'] as String?,
      channelTitle: row['channel_title'] as String?,
      channelImageUrl: row['channel_image_url'] as String?,
    );
  }

  Map<String, Object?> toSqlite() {
    return {
      "id": id,
      "guid": guid,
      "title": title,
      "subtitle": subtitle,
      "author": author,
      "description": description,
      "language": language,
      "categories": categories,
      "keywords": keywords,
      "updated": updated?.toIso8601String(),
      "published": published.toIso8601String(),
      "link": link,
      "media_url": mediaUrl,
      "media_type": mediaType,
      "media_size": mediaSize,
      "media_duration": mediaDuration,
      "media_seek_pos": mediaSeekPos,
      "image_url": imageUrl,
      "extras": jsonEncode(extras),
      "downloaded": downloaded == true ? 1 : 0,
      "played": played == true ? 1 : 0,
      "liked": liked == true ? 1 : 0,
      "channel_id": channelId,
    };
  }

  @override
  String toString() =>
      (toSqlite()
            ..remove('subtitle')
            ..remove('description'))
          .toString();
}
