import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repository/feed.dart';
import '../data/service/api/pcindex.dart';
import '../data/service/local/sqflite.dart';
import '../data/service/local/storage.dart';
import '../ui/browser/model.dart';
import '../ui/episode/model.dart';
import '../ui/channel/model.dart';
import '../ui/favorite/model.dart';
import '../ui/follow/model.dart';
import '../ui/home/model.dart';
import '../ui/search/model.dart';

List<SingleChildWidget> get providers => [
  // audio player
  Provider<AudioPlayer>(create: (context) => AudioPlayer()),
  //
  // services
  //
  Provider<DatabaseService>(create: (context) => DatabaseService()),
  Provider<StorageService>(create: (context) => StorageService()),
  Provider<PCIndexService>(create: (context) => PCIndexService()),
  //
  // repositories
  //
  Provider<FeedRepository>(
    create:
        (context) => FeedRepository(
          dbSrv: context.read<DatabaseService>(),
          stSrv: context.read<StorageService>(),
          pcIdx: context.read<PCIndexService>(),
          player: context.read<AudioPlayer>(),
        ),
  ),
  // ui: browser
  ChangeNotifierProvider(
    create:
        (context) => BrowserViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  // ui: channel
  ChangeNotifierProvider(
    create:
        (context) => FeedViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  // ui: episode
  ChangeNotifierProvider(
    create:
        (context) => EpisodeViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  // ui: favorite
  ChangeNotifierProvider(create: (context) => FavoriteViewModel()),
  // ui: follow
  ChangeNotifierProvider(
    create:
        (context) => FollowViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  // ui: home
  ChangeNotifierProvider(
    create:
        (context) => HomeViewModel(
          feedRepo: context.read<FeedRepository>(),
          player: context.read<AudioPlayer>(),
        ),
  ),
  // ui: search
  ChangeNotifierProvider(
    create:
        (context) => SearchViewModel(feedRepo: context.read<FeedRepository>()),
  ),
];
