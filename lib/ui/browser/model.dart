import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../data/repository/feed.dart';
import '../../model/feed.dart';

class BrowserViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  BrowserViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _log = Logger('BrowserViewModel');
  Feed? _feed;
  bool? _subscribed;

  bool get found => _feed != null;
  bool? get subscribed => _subscribed;

  Future fetchFeed(String url) async {
    _feed = await _feedRepo.fetchFeed(url);
    _log.fine('url: $url, feed: $_feed');
    notifyListeners();
  }

  Future subscribe() async {
    if (_feed != null) {
      _subscribed = await _feedRepo.subscribe(_feed!);
      _log.fine('subscribed: $_subscribed');
    }
    notifyListeners();
  }
}
