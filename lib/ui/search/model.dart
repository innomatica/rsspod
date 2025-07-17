import 'package:flutter/material.dart';

import '../../data/repository/feed.dart';
import '../../model/channel.dart';
import '../../model/pcindex.dart';

class SearchViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  SearchViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;
  List<Channel> _channels = [];

  List<Channel> get channels => _channels;

  Future search(PCIndexSearch method, String keywords) async {
    _channels = await _feedRepo.searchFeed(method, keywords);
    notifyListeners();
  }
}
