import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import '../../data/repository/feed.dart';
import '../../model/episode.dart';

class EpisodeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  EpisodeViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _log = Logger('EpisodeViewModel');
  Episode? _episode;

  Episode? get episode => _episode;
  AudioPlayer get player => _feedRepo.player;

  Future load(String? guid) async {
    if (guid != null) {
      _episode = await _feedRepo.getEpisodeByGuid(guid);
      _log.fine(_episode);
      notifyListeners();
    }
  }

  Future<ImageProvider> getEpisodeImage(Episode episode) async {
    return _feedRepo.getEpisodeImage(episode);
  }

  Future play() async {
    if (_episode?.guid != null) {
      await _feedRepo.playEpisode(_episode!);
      notifyListeners();
    }
  }
}
