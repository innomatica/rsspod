import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rsspod/util/constants.dart' show defaultSearchEngine;

import '../ui/browser/model.dart';
import '../ui/episode/model.dart';
import '../ui/channel/model.dart';
import '../ui/channel/view.dart';
import '../ui/episode/view.dart';
import '../ui/browser/view.dart';
import '../ui/favorite/model.dart';
import '../ui/favorite/view.dart';
import '../ui/subscribed/model.dart';
import '../ui/subscribed/view.dart';
import '../ui/home/model.dart';
import '../ui/home/view.dart';
import '../ui/search/model.dart';
import '../ui/search/view.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          HomeView(model: context.read<HomeViewModel>()..load()),
      routes: [
        // browser
        GoRoute(
          path: 'browser',
          builder: (context, state) => BrowserView(
            url: state.uri.queryParameters['url'] ?? defaultSearchEngine,
            model: context.read<BrowserViewModel>(),
          ),
        ),
        // episode
        GoRoute(
          path: 'episode',
          builder: (context, state) => EpisodeView(
            model: context.read<EpisodeViewModel>()
              ..load(state.uri.queryParameters['guid']),
          ),
        ),
        // subscribed
        GoRoute(
          path: 'subscribed',
          builder: (context, state) => SubscribedView(
            model: context.read<SubscribedViewModel>()..load(),
          ),
          routes: [
            // channel
            GoRoute(
              path: 'channel',
              builder: (context, state) => ChannelView(
                model: context.read<ChannelViewModel>()
                  ..load(state.uri.queryParameters['url']),
              ),
            ),
            // favorite
            GoRoute(
              path: 'favorite',
              builder: (context, state) => FavoriteView(
                model: context.read<FavoriteViewModel>()..load(),
              ),
            ),
            // search
            GoRoute(
              path: 'search',
              builder: (context, state) =>
                  SearchView(model: context.read<SearchViewModel>()),
            ),
          ],
        ),
      ],
    ),
  ],
);
