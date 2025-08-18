import 'dart:convert' show utf8;

import 'package:flutter/services.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;
import 'package:logging/logging.dart' show Logger;
import 'package:xml/xml.dart';

import '../../model/channel.dart';
import '../../model/episode.dart';
import '../../model/feed.dart';
import '../../model/pcindex.dart';
import '../../util/constants.dart';
import '../../util/helpers.dart';
import '../service/api/pcindex.dart';
import '../service/local/sqflite.dart';
import '../service/local/storage.dart';

class FeedRepository {
  final DatabaseService _dbSrv;
  final StorageService _stSrv;
  final PCIndexService _pcIdx;
  final AudioPlayer _player;
  FeedRepository({
    required DatabaseService dbSrv,
    required StorageService stSrv,
    required PCIndexService pcIdx,
    required AudioPlayer player,
  }) : _dbSrv = dbSrv,
       _stSrv = stSrv,
       _pcIdx = pcIdx,
       _player = player;

  final _unesc = HtmlUnescape();
  // ignore: unused_field
  final _logger = Logger('FeedRespository');

  AudioPlayer get player => _player;

  // Feed

  Future<List<Channel>> searchFeed(
    PCIndexSearch method,
    String keywords,
  ) async {
    return await _pcIdx.searchPodcasts(method, keywords);
  }

  Future<Feed?> fetchFeed(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 &&
          res.headers['content-type']?.contains("xml") == true) {
        final document = XmlDocument.parse(
          _unesc.convert(utf8.decode(res.bodyBytes)),
        );
        // first children
        final children = document.childElements;
        if (children.isNotEmpty) {
          final root = children.first;
          // rss or atom
          if (root.name.toString() == 'rss') {
            return Feed.fromRss(root, url);
          } else if (root.name.toString() == 'feed') {
            return Feed.fromAtom(root, url);
          } else if (root.name.toString() == 'rdf:RDF') {
            return Feed.fromRdf(root, url);
          }
          _logger.severe('unknown feed format');
          // throw Exception('unknown feed format');
        }
      } else {
        // http error or non xlm document
        _logger.fine('${res.statusCode}: ${res.headers['content-type']}');
      }
    } catch (e) {
      _logger.severe(e.toString);
      // throw Exception(e.toString);
    }
    return null;
  }

  // Read Channel and its Episodes
  Future<Feed?> getFeedByUrl(String url) async {
    final channel = await getChannelByUrl(url);
    if (channel != null) {
      final episodes = await getEpisodesByChannel(channel.id);
      return Feed(channel: channel, episodes: episodes);
    }
    return null;
  }

  Future<bool> subscribe(Feed feed) async {
    _logger.fine('subscribe');
    if (await createChannel(feed.channel) > 0) {
      // save episodes
      final refDate = DateTime.now().subtract(
        Duration(days: dataRetentionPeriod),
      );
      for (final episode in feed.episodes) {
        // _log.fine('episode:$episode');
        // save only up to maxRetentionDays ago
        if (episode.published.isBefore(refDate) != true) {
          episode.channelId = feed.channel.id;
          await createEpisode(episode);
        }
      }
      return true;
    }
    return false;
  }

  Future unsubscribe(int channelId) async {
    _logger.fine('unsubscribe');
    try {
      await _dbSrv.delete("DELETE FROM episodes WHERE channel_id = ?", [
        channelId,
      ]);
      await _dbSrv.delete("DELETE FROM channels WHERE id = ?", [channelId]);
      await _stSrv.deleteDirectory(channelId);
    } on Exception catch (e) {
      // rethrow;
      _logger.severe(e.toString());
    }
  }

  Future refreshFeeds({bool force = false}) async {
    _logger.fine('updateFeeds: $force');
    final channels = await getChannels();
    for (final channel in channels) {
      final today = DateTime.now();

      // published date is more than a period ago
      bool pubExpected =
          channel.published != null &&
          today.isAfter(
            channel.published!.add(
              Duration(days: channel.period ?? defaultUpdatePeriod),
            ),
          );

      // checked date is more than a period ago
      bool chkRequired =
          channel.checked != null &&
          today.isAfter(
            channel.checked!.add(
              Duration(days: channel.period ?? defaultUpdatePeriod),
            ),
          );

      _logger.fine(
        'channel:${channel.id} pubExpected:$pubExpected, chkRequired:$chkRequired',
      );

      if (force || (pubExpected && chkRequired)) {
        _logger.fine('pub:${channel.published}, chk:${channel.checked}');
        await refreshChannel(channel);
      }
    }
  }

  // Channel

  Future<List<Channel>> getChannels() async {
    try {
      final rows = await _dbSrv.queryAll("SELECT * FROM channels");
      return rows.map((e) => Channel.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<Channel?> getChannelByUrl(String url) async {
    try {
      final row = await _dbSrv.query("SELECT * FROM channels WHERE url = ?", [
        url,
      ]);
      return row != null ? Channel.fromSqlite(row) : null;
    } on Exception {
      rethrow;
    }
  }

  Future<int> createChannel(Channel channel) async {
    try {
      final data = channel.toSqlite();
      final args = List.filled(data.length, '?').join(',');
      final res = await _dbSrv.insert(
        "INSERT INTO channels(${data.keys.join(',')}) VALUES($args)"
        " ON CONFLICT(id) DO NOTHING",
        [...data.values],
      );
      if (res > 0) {
        // download channel image
        if (await _downloadResource(
              channel.id,
              channel.imageUrl ?? googleFaviconUrl(channel.url),
              chnImgFname,
            ) ==
            false) {
          final byteData = await rootBundle.load(defaultChannelImage);
          final file = await _stSrv.getFile(channel.id, chnImgFname);
          await file?.create(recursive: true);
          await file?.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );
        }
      }
      return res;
    } on Exception catch (e) {
      // rethrow;
      _logger.severe(e.toString());
      return 0;
    }
  }

  Future<int> updateChannel(int channelId, Map<String, Object> data) async {
    // _log.fine('updateChannel: $data');
    try {
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.update("UPDATE channels SET $sets WHERE id = ?", [
        ...data.values,
        channelId,
      ]);
    } on Exception catch (e) {
      // rethrow;
      _logger.severe(e.toString());
    }
    return 0;
  }

  Future<bool> refreshChannel(Channel channel) async {
    _logger.fine('refreshChannel: ${channel.id}');
    final feed = await fetchFeed(channel.url);
    if (feed != null) {
      // overwrite channel id
      feed.channel.id = channel.id;
      // mark checked
      await updateChannel(channel.id, {
        "checked": DateTime.now().toIso8601String(),
      });
      // reference date
      final refDate = DateTime.now().subtract(
        Duration(days: dataRetentionPeriod),
      );
      for (final episode in feed.episodes) {
        // inject channel id field
        episode.channelId = channel.id;
        // _log.fine('episode:${episode.guid}.${episode.published}');
        // update only back to reference date
        if (episode.published.isBefore(refDate) != true) {
          // _log.fine('create:${episode.title}');
          await _refreshEpisode(episode);
        }
      }
      // remove expired episodes and their data
      await _purgeEpisodes(channel.id);
      return true;
    }
    return false;
  }

  // Episode

  Future<List<Episode>> getEpisodes({int period = defaultDisplayPeriod}) async {
    final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
    try {
      final rows = await _dbSrv.queryAll(
        """
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url,
        channels.url as channel_url
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE DATE(episodes.published) > ?
      ORDER BY episodes.published DESC""",
        [start],
      );
      return rows.map((e) => Episode.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<List<Episode>> getEpisodesByChannel(
    int channelId, {
    int period = 90,
  }) async {
    final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
    try {
      final rows = await _dbSrv.queryAll(
        """
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url,
        channels.url as channel_url
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE episodes.channel_id = ? 
        AND DATE(episodes.published) > ?
      ORDER BY episodes.published DESC""",
        [channelId, start],
      );
      return rows.map((e) => Episode.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<Episode?> getEpisodeByGuid(String? guid) async {
    try {
      final row = await _dbSrv.query(
        """
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE episodes.guid = ?""",
        [guid],
      );
      return row != null ? Episode.fromSqlite(row) : null;
    } on Exception {
      rethrow;
    }
  }

  Future<int> createEpisode(Episode episode) async {
    try {
      final data = episode.toSqlite();
      // data.remove('id');
      final args = List.filled(data.length, '?').join(',');
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.insert(
        "INSERT INTO episodes(${data.keys.join(',')}) VALUES($args)"
        " ON CONFLICT(guid) DO UPDATE SET $sets",
        [...data.values, ...data.values],
      );
    } on Exception catch (e) {
      _logger.severe(e.toString());
      rethrow;
    }
  }

  Future<int> updateEpisode(int episodeId, Map<String, Object?> data) async {
    try {
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.update("UPDATE episodes SET $sets WHERE id = ?", [
        ...data.values,
        episodeId,
      ]);
    } on Exception {
      rethrow;
    }
  }

  Future<bool> downloadEpisode(Episode episode) async {
    if (episode.channelId != null && episode.mediaUrl != null) {
      if (await _downloadResource(
        episode.channelId!,
        episode.mediaUrl!,
        episode.mediaFname,
      )) {
        // download successful
        episode.downloaded = true;
        // note downloaded field type is integer
        await updateEpisode(episode.id, {"downloaded": 1});
        return true;
      }
    }
    return false;
  }

  // Audio Player

  Future<IndexedAudioSource?> getAudioSource(Episode episode) async {
    final audioUri = await _getAudioUri(
      episode.channelId,
      episode.mediaUrl,
      episode.mediaFname,
    );

    if (audioUri != null) {
      return AudioSource.uri(
        audioUri,
        tag: MediaItem(
          id: episode.guid,
          title: episode.title ?? "Title Unknown",
          album: episode.channelTitle ?? "Album Unknown",
          artist: episode.author,
          artUri:
              await _getImageUri(
                episode.channelId,
                episode.imageUrl,
                episode.imageFname,
              ) ??
              await _getImageUri(
                episode.channelId,
                episode.channelImageUrl,
                chnImgFname,
              ),
          extras: {},
        ),
      );
    }
    return null;
  }

  Future playEpisode(Episode episode) async {
    _logger.fine('requested: ${episode.guid}');
    _logger.fine(
      'current:${(_player.audioSource as IndexedAudioSource?)?.tag.id}',
    );
    if ((_player.audioSource as IndexedAudioSource?)?.tag.id == episode.guid) {
      _logger.fine('current episode: do toggle playing');
      _player.playing ? await _player.pause() : await _player.play();
    } else {
      _logger.fine('new episode');
      final audioSource = await getAudioSource(episode);
      // final audioSource = episode.toAudioSource();
      if (audioSource != null) {
        _logger.fine('audioSource:${audioSource.tag}');
        await _player.stop();
        await _player.setAudioSource(audioSource);
        await _player.seek(Duration(seconds: episode.mediaSeekPos ?? 0));
        await _player.play();
      }
    }
  }

  Future addToPlayList(Episode episode) async {
    final audioSource = await getAudioSource(episode);
    // final audioSource = episode.toAudioSource();
    if (audioSource != null) {
      _logger.fine('audioSource:${audioSource.tag}');
      // just_audio version 0.10 specific
      await _player.addAudioSource(audioSource);
    }
  }

  Future stop() async {
    await _player.stop();
  }

  // Others

  Future setPlayed(String guid) async {
    try {
      // delete dowloaded file if exists
      final row = await _dbSrv.query("SELECT * FROM episodes WHERE guid = ?", [
        guid,
      ]);
      // _log.fine('row: $row');
      if (row != null) {
        final episode = Episode.fromSqlite(row);
        final file = await _stSrv.getFile(
          episode.channelId,
          episode.mediaFname,
        );
        if (file?.existsSync() == true) {
          await _stSrv.deleteFile(episode.channelId!, episode.mediaFname);
        }
      }
      // set played to TRUE as well as downloaded to FALSE
      await _dbSrv.update(
        "UPDATE episodes SET played = TRUE, downloaded = FALSE WHERE guid = ?",
        [guid],
      );
      // remove audio source from sequence
      final idx = _player.sequence.indexWhere((e) => e.tag.id == guid);
      // _log.fine('idx:$idx');
      if (idx >= 0) {
        _player.removeAudioSourceAt(idx);
      }
    } on Exception {
      rethrow;
    }
  }

  Future clearPlayed(String guid) async {
    try {
      await _dbSrv.update("UPDATE episodes SET played = FALSE WHERE guid = ?", [
        guid,
      ]);
    } on Exception {
      rethrow;
    }
  }

  Future setLiked(String guid) async {
    try {
      await _dbSrv.update("UPDATE episodes SET liked = TRUE WHERE guid = ?", [
        guid,
      ]);
    } on Exception {
      rethrow;
    }
  }

  Future clearLiked(String guid) async {
    try {
      await _dbSrv.update("UPDATE episodes SET liked = FALSE WHERE guid = ?", [
        guid,
      ]);
    } on Exception {
      rethrow;
    }
  }

  Future updateBookmark(String guid, int bookmark) async {
    try {
      await _dbSrv.update(
        "UPDATE episodes SET media_seek_pos = $bookmark WHERE guid = ?",
        [guid],
      );
    } on Exception {
      rethrow;
    }
  }

  // Internal use

  Future _refreshEpisode(Episode episode) async {
    final file = await _stSrv.getFile(episode.channelId, episode.mediaFname);
    final data = episode.toSqlite();
    // fields that have to be retained
    data.remove('liked');
    data.remove('played');
    // set downloaded field based on the stored file
    data['downloaded'] = file?.existsSync() == true;
    try {
      _logger.fine('upsert episode:${episode.id}');
      final args = List.filled(data.length, '?').join(',');
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.insert(
        "INSERT INTO episodes(${data.keys.join(',')}) VALUES($args)"
        " ON CONFLICT(guid) DO UPDATE SET $sets",
        [...data.values, ...data.values],
      );
    } on Exception {
      rethrow;
    }
  }

  Future _purgeEpisodes(int? channelId) async {
    try {
      if (channelId != null) {
        _logger.fine('purgeChannel');
        final episodes = await getEpisodesByChannel(channelId);
        final refDate = DateTime.now().subtract(
          Duration(days: dataRetentionPeriod),
        );
        for (final episode in episodes) {
          // delete expired episodes and its local media data
          if (episode.published.isBefore(refDate) == true) {
            await _dbSrv.delete("DELETE FROM episodes WHERE guid = ?", [
              episode.guid,
            ]);
            await _stSrv.deleteFile(channelId, episode.mediaFname);
            if (episode.imageFname != null) {
              await _stSrv.deleteFile(channelId, episode.imageFname!);
            }
          }
          // delete local media data of played episode
          if (episode.played == true) {
            await _stSrv.deleteFile(channelId, episode.mediaFname);
          }
        }
      }
    } on Exception {
      rethrow;
    }
  }

  Future<bool> _downloadResource(
    int channelId,
    String? url,
    String fname,
  ) async {
    try {
      final client = http.Client();
      final req = http.Request('GET', Uri.parse(url ?? ""));
      final res = await client.send(req);
      if (res.statusCode == 200) {
        _logger.fine('downloading: $url to $fname');
        final file = await _stSrv.getFile(channelId, fname);
        if (file != null) {
          await file.create(recursive: true);
          final sink = file.openWrite();
          await res.stream.pipe(sink);
          return true;
        }
      }
      client.close();
    } catch (e) {
      // rethrow;
      _logger.severe(e.toString());
    }
    return false;
  }

  Future<Uri?> _getAudioUri(int? channelId, String? url, String? fname) async {
    if (channelId != null && url != null) {
      final file = await _stSrv.getFile(channelId, fname);
      if (file != null && file.existsSync()) {
        return Uri.file(file.path);
      }
      return Uri.parse(url);
    }
    return null;
  }

  Future<Uri?> _getImageUri(int? channelId, String? url, String? fname) async {
    final file = await _stSrv.getFile(channelId, fname);
    if (file != null) {
      if (file.existsSync()) {
        return Uri.file(file.path);
      } else if (channelId != null && url != null && fname != null) {
        if (await _downloadResource(channelId, url, fname)) {
          return Uri.file(file.path);
        }
        // failed download: probably url is invalid
        return Uri.tryParse(url);
      }
    }
    return null;
  }
}
