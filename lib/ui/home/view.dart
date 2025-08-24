import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../util/constants.dart';
import '../../util/helpers.dart' show secsToHhMmSs, sizeStr, yymmdd;
import '../../util/miniplayer.dart' show MiniPlayer;
import '../../util/qrcodeimg.dart' show QrCodeImage;
import '../../util/widgets.dart' show ChannelImage;
import 'model.dart';

enum ViewFilter { unplayed, all, downloaded, liked }

extension ViewFilterExt on ViewFilter {
  IconData get icon {
    switch (this) {
      case ViewFilter.unplayed:
        return Icons.filter_list_rounded;
      case ViewFilter.all:
        return Icons.menu_rounded;
      case ViewFilter.downloaded:
        return Icons.storage_rounded;
      case ViewFilter.liked:
        return Icons.favorite_outline_rounded;
    }
  }

  ViewFilter get next {
    switch (this) {
      case ViewFilter.unplayed:
        return ViewFilter.all;
      case ViewFilter.all:
        return ViewFilter.downloaded;
      case ViewFilter.downloaded:
        // skip liked
        // return ViewFilter.liked;
        return ViewFilter.unplayed;
      case ViewFilter.liked:
        return ViewFilter.unplayed;
    }
  }
}

class HomeView extends StatefulWidget {
  final HomeViewModel model;

  const HomeView({super.key, required this.model});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int pageIndex = 0;
  ViewFilter filter = ViewFilter.unplayed;
  Timer? sleepTimer;
  int sleepCount = 0;

  void _setSleepTimer() {
    sleepCount = sleepCount <= 0
        ? sleepCount = 60
        : sleepCount > 45
        ? sleepCount = 45
        : sleepCount > 30
        ? sleepCount = 30
        : sleepCount > 10
        ? sleepCount = 10
        : sleepCount > 5
        ? sleepCount = 5
        : sleepCount = 0;
    if (sleepCount == 0) {
      sleepTimer?.cancel();
    } else {
      sleepTimer ??= Timer.periodic(Duration(seconds: 60), (timer) {
        sleepCount--;
        setState(() {});
        if (sleepCount <= 0) {
          timer.cancel();
          widget.model.stop();
          sleepTimer = null;
        }
      });
    }
    setState(() {});
  }

  Widget _buildEpisodeList() {
    final episodes = filter == ViewFilter.unplayed
        ? widget.model.unplayed
        : filter == ViewFilter.downloaded
        ? widget.model.downloaded
        : filter == ViewFilter.liked
        ? widget.model.liked
        : widget.model.episodes;
    return episodes.isNotEmpty
        ? ListView.separated(
            itemCount: episodes.length,
            separatorBuilder: (context, _) =>
                Divider(indent: 0, endIndent: 0, height: 0),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              final downloaded = episode.downloaded == true;
              final played = episode.played == true;
              // final liked = episode.liked == true;
              return ListTile(
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                selectedTileColor: Theme.of(context).colorScheme.primary,
                dense: true,
                enabled: !played,
                selected: episode.guid == widget.model.currentId,
                contentPadding: EdgeInsets.only(left: 8, right: 8, top: 8),
                title: Row(
                  spacing: 8,
                  children: [
                    // channel image
                    GestureDetector(
                      onTap: () {
                        context.go(
                          Uri(
                            path: "/subscribed/channel",
                            queryParameters: {'url': episode.channelUrl},
                          ).toString(),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(5.0),
                        child: ChannelImage(
                          episode,
                          width: 60,
                          height: 60,
                          opacity: played ? 0.5 : 1.0,
                        ),
                      ),
                    ),
                    // channel title, pubdate, episode title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 4.0,
                            children: [
                              // channel title
                              Expanded(
                                child: Text(
                                  episode.channelTitle ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // episode title
                          Text(
                            episode.title ?? 'unknown',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // pub date, duration/size, buttons
                subtitle: Row(
                  // spacing: 4,
                  children: [
                    // pub date
                    Text(yymmdd(episode.published)),
                    SizedBox(width: 12),
                    // duration or size
                    episode.mediaDuration != null
                        ? Text(secsToHhMmSs(episode.mediaDuration))
                        : Text(sizeStr(episode.mediaSize)),
                    Expanded(child: SizedBox()),
                    // download button
                    IconButton(
                      icon: Icon(
                        downloaded
                            ? Icons.storage_rounded
                            : Icons.download_rounded,
                      ),
                      onPressed: downloaded || played
                          ? null
                          : () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'downloading ${episode.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                              await widget.model.downloadEpisode(episode);
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                    // // liked
                    // IconButton(
                    //   icon: Icon(
                    //     liked
                    //         ? Icons.favorite_rounded
                    //         : Icons.favorite_outline_rounded,
                    //   ),
                    //   onPressed: () => widget.model.toggleLiked(episode),
                    //   visualDensity: VisualDensity.compact,
                    // ),
                    // played
                    IconButton(
                      icon: Icon(
                        played
                            ? Icons.remove_done_rounded
                            : Icons.done_all_rounded,
                      ),
                      onPressed: () => widget.model.togglePlayed(episode),
                      visualDensity: VisualDensity.compact,
                    ),
                    // add to playlist
                    // just_audio version 0.10 specific
                    IconButton(
                      icon: Icon(Icons.playlist_add_rounded),
                      onPressed: played
                          ? null
                          : () => widget.model.addToPlayList(episode),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                onTap: played ? null : () => widget.model.playEpisode(episode),
                onLongPress: () async {
                  context.go(
                    Uri(
                      path: '/episode',
                      queryParameters: {'guid': episode.guid},
                    ).toString(),
                  );
                },
              );
            },
          )
        : Center(
            child: IconButton(
              icon: Image.asset(assetImageRecording, width: 200, height: 200),
              onPressed: () => context.go('/subscribed'),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text(appName),
            actions: [
              // sleep timer
              TextButton.icon(
                onPressed: () => _setSleepTimer(),
                icon: Icon(Icons.snooze_rounded, size: 24),
                iconAlignment: IconAlignment.end,
                label: Text(sleepCount > 0 ? sleepCount.toString() : ''),
              ),
              // episode filter
              IconButton(
                onPressed: () => setState(() => filter = filter.next),
                icon: Icon(filter.icon),
              ),
              // subscriptions
              IconButton(
                onPressed: () => context.go('/subscribed'),
                icon: Icon(Icons.subscriptions_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.model.refresh,
            child: _buildEpisodeList(),
          ),
          drawer: SideBar(model: widget.model),
          // https://github.com/flutter/flutter/issues/50314
          bottomNavigationBar: MiniPlayer(),
        );
      },
    );
  }
}

class SideBar extends StatefulWidget {
  final HomeViewModel model;
  const SideBar({super.key, required this.model});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int displayPeriod = defaultDisplayPeriod;
  String searchEngine = defaultSearchEngine;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  dispose() {
    super.dispose();
    _dispose();
  }

  Future _init() async {
    setState(() {
      displayPeriod = widget.model.displayPeriod;
    });
  }

  Future _dispose() async {
    await widget.model.setDisplayPeriod(displayPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ListTile(
            title: Text("Episode display period"),
            subtitle: Row(
              children: [
                Text('show episodes back to'),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: displayPeriod,
                  underline: SizedBox(),
                  items: displayPeriods.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      displayPeriod = value ?? displayPeriod;
                    });
                  },
                ),
                SizedBox(width: 4),
                Text('days'),
              ],
            ),
          ),
          Divider(indent: 16, endIndent: 16),
          ListTile(
            title: Text('App version'),
            subtitle: Text(appVersion),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
            contentPadding: EdgeInsets.only(left: 16.0, right: 8.0),
            trailing: IconButton(
              onPressed: () {
                if (mounted) context.pop();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                        "Download $appName",
                        style: TextStyle(color: Colors.grey),
                      ),
                      backgroundColor: Colors.white,
                      contentPadding: EdgeInsets.all(32.0),
                      content: Column(
                        spacing: 16.0,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrCodeImage(data: releaseUrl),
                          Text(
                            releaseUrl,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.qr_code_2_rounded, size: 32.0),
            ),
          ),
          ListTile(
            title: Text('Source code repository'),
            subtitle: Text('github'),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
          ),
          ListTile(
            title: Text('Developer'),
            subtitle: Text('innomatic'),
            onTap: () => launchUrl(Uri.parse(developerWebsite)),
          ),
          ListTile(
            title: Text('Attributions'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton(
                  child: Text('Podcast Index Search Engine'),
                  onPressed: () => launchUrl(Uri.parse(pcIdxUrl)),
                ),
                TextButton(
                  child: Text('Microphone icons by Freepik'),
                  onPressed: () => launchUrl(Uri.parse(micIconUrl)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
