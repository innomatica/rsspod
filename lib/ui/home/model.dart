import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repository/feed.dart';
import '../../model/channel.dart';
import '../../model/episode.dart';

import '../../util/constants.dart';

class HomeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  final AudioPlayer _player;
  HomeViewModel({required FeedRepository feedRepo, required AudioPlayer player})
    : _feedRepo = feedRepo,
      _player = player {
    _init();
  }

  // ignore: unused_field
  final _logger = Logger('HomeViewModel');
  List<Channel> _channels = <Channel>[];
  List<Episode> _episodes = <Episode>[];

  SharedPreferences? _spref;

  IndexedAudioSource? _currentSource;
  StreamSubscription? _subPlayer;
  StreamSubscription? _subSeqState;

  List<Episode> get episodes => _episodes;

  List<Episode> get unplayed =>
      _episodes.where((e) => e.played != true).toList();
  List<Episode> get downloaded =>
      _episodes.where((e) => e.downloaded == true).toList();
  List<Episode> get liked => _episodes.where((e) => e.liked == true).toList();
  IndexedAudioSource? get currentSource => _currentSource;
  String? get currentId => _currentSource?.tag.id;

  void _init() async {
    _logger.fine('init');

    _subPlayer = _player.playerStateStream.listen((event) async {
      _logger.fine('playerState: ${event.playing} - ${event.processingState}');
      //
      // playing: true / false
      // processingState: idle / loading / buffering /  ready/ completed
      //
      if (event.playing == false &&
          event.processingState == ProcessingState.ready) {
        // paused
        await _handlePlayerStateChange(event);
      }
      if (event.playing == true &&
          (event.processingState == ProcessingState.buffering ||
              event.processingState == ProcessingState.completed)) {
        // seek
        await _handlePlayerStateChange(event);
      }
    });
    _subSeqState = _player.sequenceStateStream.listen((event) async {
      _logger.fine(
        'idx src seq: ${event.currentIndex} ${event.currentSource} ${event.sequence}',
      );
      //
      // currentIndex
      // currentSource
      // sequence
      await _handleSequenceStateChange(event);
    });

    _spref = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _subPlayer?.cancel();
    _subSeqState?.cancel();
    super.dispose();
  }

  Future _handleSequenceStateChange(SequenceState state) async {
    if (_currentSource != state.currentSource) {
      //
      // set the previous episode played : CAN BE PROBLEMATIC
      //
      if (_currentSource?.tag.id != null && state.sequence.length > 1) {
        _logger.fine('set played: ${_currentSource?.tag.title}');
        await _feedRepo.setPlayed(_currentSource?.tag.id);
      }
      //
      _currentSource = state.currentSource;
      notifyListeners();
      // await load();
    }
  }

  Future _handlePlayerStateChange(PlayerState state) async {
    final index = _player.currentIndex;
    final sequence = _player.sequence;
    final position = _player.position;
    final duration = _player.duration;
    // _log.fine('handlePlayerStateChange: $index, $sequence, $position, $duration');

    if (index != null &&
        sequence.isNotEmpty == true &&
        sequence.length > index &&
        position > Duration(seconds: 30)) {
      final source = sequence[index];
      if (duration != null && (position + Duration(seconds: 30) > duration)) {
        // end of the media
        _logger.fine('set played: ${source.tag.title}');
        await _feedRepo.setPlayed(source.tag.id);
        await load();
      } else {
        // paused or seek
        _logger.fine('update bookmark: ${source.tag.title}');
        await _feedRepo.updateBookmark(source.tag.id, position.inSeconds);
      }
    }
  }

  Future load() async {
    _logger.fine('load');
    _channels = await _feedRepo.getChannels();

    final period = _spref?.getInt(pKeyDisplayPeriod) ?? defaultDisplayPeriod;
    final refDate = DateTime.now().subtract(Duration(days: period));

    _episodes.clear();
    for (final channel in _channels) {
      final episodes = await _feedRepo.getEpisodesByChannel(channel.id);
      _episodes.addAll(episodes.where((e) => e.published.isAfter(refDate)));
      _episodes.sort((a, b) => b.published.compareTo(a.published));
    }
    notifyListeners();
  }

  Future refreshData() async {
    _logger.fine('refreshData');
    await _feedRepo.refreshFeeds(force: false);
    await load();
  }

  // Audio

  Future playEpisode(Episode episode) async {
    await _feedRepo.playEpisode(episode);
  }

  Future stop() async {
    await _feedRepo.stop();
  }

  Future addToPlayList(Episode episode) async {
    await _feedRepo.addToPlayList(episode);
    // notification done via player.sequenceStream
    // notifyListeners();
  }

  Future togglePlayed(Episode episode) async {
    if (episode.played == true) {
      // clear
      // _log.fine('clear played');
      await _feedRepo.clearPlayed(episode.guid);
    } else {
      // set
      // _log.fine('set played');
      await _feedRepo.setPlayed(episode.guid);
      // }
    }
    _episodes = await _feedRepo.getEpisodes(
      period: _spref?.getInt(pKeyDisplayPeriod) ?? defaultDisplayPeriod,
    );
    notifyListeners();
  }

  Future toggleLiked(Episode episode) async {
    if (episode.liked == true) {
      await _feedRepo.clearLiked(episode.guid);
    } else {
      await _feedRepo.setLiked(episode.guid);
    }
    _episodes = await _feedRepo.getEpisodes(
      period: _spref?.getInt(pKeyDisplayPeriod) ?? defaultDisplayPeriod,
    );
    notifyListeners();
  }

  Future downloadEpisode(Episode episode) async {
    await _feedRepo.downloadEpisode(episode);
    _episodes = await _feedRepo.getEpisodes(
      period: _spref?.getInt(pKeyDisplayPeriod) ?? defaultDisplayPeriod,
    );
    notifyListeners();
  }

  // Settings

  int getDisplayPeriod() {
    return _spref?.getInt(pKeyDisplayPeriod) ?? defaultDisplayPeriod;
  }

  Future setDisplayPeriod(int value) async {
    await _spref?.setInt(pKeyDisplayPeriod, value);
  }
}
