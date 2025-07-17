import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../data/repository/feed.dart';
import '../../model/feed.dart';

class FeedViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  FeedViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;
  // ignore: unused_field
  final _log = Logger('FeedViewModel');

  bool _subscribed = false;
  String? _error;
  Feed? _feed;

  bool get subscribed => _subscribed;
  String? get error => _error;
  Feed? get feed => _feed;

  Future load(String? url) async {
    _error = null;
    _feed = null;

    if (url != null && url.isNotEmpty) {
      // try local database first
      final feed = await _feedRepo.getFeed(url);
      // final feed = null;
      if (feed != null) {
        // local found: already subscribed
        _subscribed = true;
        _feed = feed;
      } else {
        // try feed source
        _subscribed = false;
        _feed = await _feedRepo.fetchFeed(url);
      }
      // _log.fine('_feed:$_feed');
    } else {
      _error = "invalid URL";
    }
    notifyListeners();
  }

  Future subscribe() async {
    if (!_subscribed && _feed != null) {
      _log.fine('subscribe');
      if (await _feedRepo.subscribe(_feed!)) {
        _subscribed = true;
      }
    }
    notifyListeners();
  }

  Future unsubscribe() async {
    if (_subscribed && _feed?.channel.id != null) {
      _log.fine('unsubscribe');
      await _feedRepo.unsubscribe(_feed!.channel.id!);
      _subscribed = false;
    }
    notifyListeners();
  }

  Future<ImageProvider> getChannelImage() async {
    // _log.fine('getImage:$url');
    return _feedRepo.getChannelImage(_feed!.channel);
  }

  Future refreshChannel() async {
    if (_feed != null && _subscribed) {
      _feedRepo.refreshChannel(_feed!.channel);
    }
  }

  Future updatePeriod(int period) async {
    if (_feed?.channel.id != null && _subscribed) {
      // _log.fine('updatePeriod:$period');
      final res = await _feedRepo.updateChannel(_feed!.channel.id!, {
        "period": period,
      });
      if (res == 1) {
        _feed!.channel.period = period;
      }
      notifyListeners();
    }
  }
}
