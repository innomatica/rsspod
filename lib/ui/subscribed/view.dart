import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../util/widgets.dart' show ChannelImage;
import 'model.dart';

enum SearchEngine { brave, duckduckgo, ecosia, google }

extension SearchEngineExt on SearchEngine {
  String get url {
    switch (this) {
      case SearchEngine.brave:
        return "https://search.brave.com/search?q=";
      case SearchEngine.duckduckgo:
        return "https://duckduckgo.com/?q=";
      case SearchEngine.ecosia:
        return "https://ecosia.org/search?q=";
      case SearchEngine.google:
        return "https://www.google.com/search?q=";
    }
  }
}

class SubscribedView extends StatelessWidget {
  final SubscribedViewModel model;
  const SubscribedView({super.key, required this.model});

  void _handleSearch(BuildContext context, String keyword, SearchEngine e) {
    if (keyword.isNotEmpty) {
      String url = "";
      if (keyword.contains("/")) {
        // direct url to the rss page
        url = keyword.startsWith('http') ? keyword : 'https://$keyword';
      } else {
        // query params for search
        final q = Uri.encodeQueryComponent('$keyword rss feed');
        url = '${e.url}$q';
      }
      context.push(
        Uri(path: '/browser', queryParameters: {"url": url}).toString(),
      );
      Navigator.pop(context);
    }
  }

  Future _showModal(BuildContext context) async {
    final iconColor = Theme.of(context).colorScheme.primary;
    String keyword = '';
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: [
          // podcast index
          ListTile(
            title: Row(
              spacing: 8.0,
              children: [
                Icon(Icons.search_rounded, color: iconColor),
                Text("Search Using Podcast Index"),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("open podcast search engine")],
            ),
            onTap: () {
              context.go('/subscribed/search');
              Navigator.of(context).pop();
            },
          ),
          // curated list
          ListTile(
            title: Row(
              spacing: 8.0,
              children: [
                Icon(Icons.favorite_outline_rounded, color: iconColor),
                Text("Choose from Curated List"),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('RssPod Favorite Feeds')],
            ),
            onTap: () {
              context.go('/subscribed/favorite');
              Navigator.of(context).pop();
            },
          ),
          // search web
          ListTile(
            title: Row(
              spacing: 8.0,
              children: [
                Icon(Icons.travel_explore_rounded, color: iconColor),
                Text("Search Web by Keyword / URL"),
              ],
            ),
            subtitle: TextField(
              decoration: InputDecoration(
                hintText: "keyword or url",
                suffix: MenuAnchor(
                  menuChildren: SearchEngine.values.map((e) {
                    return MenuItemButton(
                      child: Text(e.name),
                      onPressed: () {
                        _handleSearch(context, keyword, e);
                      },
                    );
                  }).toList(),
                  builder: (context, controller, _) {
                    return IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        controller.isOpen
                            ? controller.close()
                            : controller.open();
                      },
                    );
                  },
                ),
              ),
              onChanged: (value) => keyword = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(BuildContext context) {
    return model.channels.isNotEmpty
        ? GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width ~/ 120,
            children: model.channels.map((e) {
              return GestureDetector(
                onTap: () {
                  context.go(
                    Uri(
                      path: '/subscribed/channel',
                      queryParameters: {'url': e.url},
                    ).toString(),
                  );
                },
                child: GridTile(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: ChannelImage(e, width: 100, height: 100),
                      ),
                      // title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          e.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        : Center(
            child: Opacity(
              opacity: 0.3,
              child: Icon(Icons.subscriptions_rounded, size: 100),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          // onPressed: () => context.pop(),
          onPressed: () => context.go('/'),
        ),
        title: Text('Subscriptions'),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => _buildChannelList(context),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showModal(context),
      ),
    );
  }
}
