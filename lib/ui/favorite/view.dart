import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../model/favorite.dart';
import 'model.dart';

class FavoriteView extends StatelessWidget {
  final FavoriteViewModel model;
  const FavoriteView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_outlined),
          onPressed: () => context.pop(),
        ),
        title: Text('Starter Pack'),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              children:
                  model.items.map((e) => FavoriteTile(channel: e)).toList(),
            ),
          );
        },
      ),
    );
  }
}

class FavoriteTile extends StatelessWidget {
  final Favorite channel;
  const FavoriteTile({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 16,
      color: Theme.of(context).colorScheme.primary,
    );
    final keywordStyle = TextStyle(fontSize: 12);
    final descriptionStyle = TextStyle(fontWeight: FontWeight.w300);
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channel.title ?? "unknown title", style: titleStyle),
          Text(
            channel.keywords ?? "",
            style: keywordStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      subtitle: Text(
        channel.description ?? "",
        style: descriptionStyle,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        context.go(
          Uri(
            path: "/channel",
            queryParameters: {"url": channel.url},
          ).toString(),
        );
      },
    );
  }
}
