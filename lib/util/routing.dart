import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/browser/model.dart';
import '../ui/episode/model.dart';
import '../ui/channel/model.dart';
import '../ui/channel/view.dart';
import '../ui/episode/view.dart';
import '../ui/browser/view.dart';
import '../ui/favorite/model.dart';
import '../ui/favorite/view.dart';
import '../ui/follow/model.dart';
import '../ui/follow/view.dart';
import '../ui/home/model.dart';
import '../ui/home/view.dart';
import '../ui/search/model.dart';
import '../ui/search/view.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder:
          (context, state) =>
              HomeView(model: context.read<HomeViewModel>()..load()),
      routes: [
        // browser
        GoRoute(
          path: 'browser',
          builder:
              (context, state) =>
                  BrowserView(model: context.read<BrowserViewModel>()),
        ),
        // channel
        GoRoute(
          path: 'channel',
          builder:
              (context, state) => FeedView(
                model:
                    context.read<FeedViewModel>()
                      ..load(state.uri.queryParameters['url']),
              ),
        ),
        // episode
        GoRoute(
          path: 'episode',
          builder:
              (context, state) => EpisodeView(
                model:
                    context.read<EpisodeViewModel>()
                      ..load(state.uri.queryParameters['guid']),
              ),
        ),
        // favorite
        GoRoute(
          path: 'favorite',
          builder:
              (context, state) => FavoriteView(
                model: context.read<FavoriteViewModel>()..load(),
              ),
        ),
        // follow
        GoRoute(
          path: 'follow',
          builder:
              (context, state) =>
                  FollowView(model: context.read<FollowViewModel>()..load()),
        ),
        // search
        GoRoute(
          path: 'search',
          builder:
              (context, state) =>
                  SearchView(model: context.read<SearchViewModel>()),
        ),
      ],
    ),
  ],
);
