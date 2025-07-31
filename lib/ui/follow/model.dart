import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../data/repository/feed.dart';
import '../../model/channel.dart';

class FollowViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  FollowViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _log = Logger('FollowViewModel');

  List<Channel> _channels = [];

  List<Channel> get channels => _channels;

  Future load() async {
    _log.fine('load');
    _channels = await _feedRepo.getChannels();
    notifyListeners();
  }

  Future<ImageProvider> getChannelImage(Channel channel) async {
    return _feedRepo.getChannelImage(channel);
  }
}
