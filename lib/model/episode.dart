import 'dart:convert';

// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart'
//     show MediaItem;

// import 'sqlite.dart';

class Episode {
  int? id; // db specific: primary key
  String guid;
  String? title;
  String? subtitle;
  String? author;
  String? description;
  String? language;
  String? categories;
  String? keywords;
  DateTime? updated;
  DateTime? published;
  String? link;
  String? mediaUrl;
  String? mediaType;
  int? mediaSize;
  int? mediaDuration;
  int? mediaSeekPos;
  String? imageUrl;
  Map<String, dynamic>? extras;
  int? channelId;
  bool? downloaded;
  bool? played;
  bool? liked;
  String? channelTitle; // db field
  String? channelImageUrl; // db field

  Episode({
    this.id,
    required this.guid,
    this.title,
    this.subtitle,
    this.author,
    this.description,
    this.language,
    this.categories,
    this.keywords,
    this.updated,
    this.published,
    this.link,
    this.mediaUrl,
    this.mediaType,
    this.mediaSize,
    this.mediaDuration,
    this.mediaSeekPos,
    this.imageUrl,
    this.extras,
    this.channelId,
    this.downloaded,
    this.played,
    this.liked,
    this.channelTitle,
    this.channelImageUrl,
  });

  // url could be used as guid
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
      updated:
          row['updated'] != null
              ? DateTime.tryParse(row['updated'] as String)
              : null,
      published:
          row['published'] != null
              ? DateTime.tryParse(row['published'] as String)
              : null,
      link: row['link'] as String?,
      mediaUrl: row['media_url'] as String?,
      mediaType: row['media_type'] as String?,
      mediaSize: row['media_size'] != null ? row['media_size'] as int : null,
      mediaDuration:
          row['media_duration'] != null ? row['media_duration'] as int : null,
      mediaSeekPos:
          row['media_seek_pos'] != null ? row['media_seek_pos'] as int : null,
      imageUrl: row['image_url'] as String?,
      extras: row['extra'] != null ? jsonDecode(row['extras'] as String) : null,
      channelId: row['channel_id'] != null ? row['channel_id'] as int : null,
      downloaded: row['downloaded'] == 1 ? true : false,
      played: row['played'] == 1 ? true : false,
      liked: row['liked'] == 1 ? true : false,
      // db fields
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
      "published": published?.toIso8601String(),
      "link": link,
      "media_url": mediaUrl,
      "media_type": mediaType,
      "media_size": mediaSize,
      "media_duration": mediaDuration,
      "media_seek_pos": mediaSeekPos,
      "image_url": imageUrl,
      "extras": jsonEncode(extras),
      "channel_id": channelId,
      "downloaded": downloaded == true ? 1 : 0,
      "played": played == true ? 1 : 0,
      "liked": liked == true ? 1 : 0,
    };
  }

  @override
  String toString() =>
      (toSqlite()
            ..remove('subtitle')
            ..remove('description'))
          .toString();
}
